extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var collision_shape : Shape3D = collision.shape
#timer period generation new enemies on a map
@onready var timer_create_new_enemy : Timer = $timer_create_new_enemy
@export var prefabenemy : PackedScene
@export var player: CharacterBody3D
@export var world: Node3D

var enemy_two_wave_material = preload("res://sprites/thunderbolt.png")
#generation count enemies on a map
var portal_create_enemy_count = 4
#generation list enemies on a map
var list_enemy : Array
#generation list new enemies on a map
var list_new_enemy : Array
#generation count new enemies on a map
var portal_create_new_enemy_count = 1
#groupe's size new enemies
var portal_create_new_enemy_groupe_count = 2
#count enemy increase after reload portal
var portal_reload_enemy_increase = 1
# modificators value's probability
var probability_modificator = 50.0
# modificators value's maximum probability
var probability_modificator_maximum=50
# modificators value's increase= probability
var probability_modificator_increase=1

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:		
		portal_create_enemy_count = config.get_value("portal", "portal_create_enemy_count", portal_create_enemy_count)
		portal_create_new_enemy_count = config.get_value("portal", "portal_create_new_enemy_count", portal_create_new_enemy_count)
		timer_create_new_enemy.wait_time = config.get_value("portal", "portal_create_new_enemy_time", 5)
		portal_create_new_enemy_groupe_count = config.get_value("portal", "portal_create_new_enemy_groupe_count", portal_create_new_enemy_groupe_count)
		portal_reload_enemy_increase = config.get_value("portal", "portal_reload_enemy_increase", portal_reload_enemy_increase)	
		probability_modificator =  config.get_value("portal", "probability_modificator", probability_modificator)
		probability_modificator_maximum =  config.get_value("portal", "probability_modificator_maximum", probability_modificator_maximum)
		probability_modificator_increase =  config.get_value("portal", "probability_modificator_increase", probability_modificator_increase)
		#config.save("res://settings.cfg")
	config = null		

func _add_child():
	var angle_shift = 330.0 / portal_create_enemy_count
	var angle = 0
	for i in range(0, portal_create_enemy_count, 1):
		var enemy = create_enemy()		
		world.add_child(enemy)		
		enemy._set_portal(self, angle)
		angle += angle_shift

func create_enemy()->Node:
	var enemy = prefabenemy.instantiate()
	enemy.player = player
	enemy.world = world
	enemy.probability_modificator = probability_modificator
	list_enemy.append(enemy)	
	return enemy

func portal_process_stop() -> void:
	visible = false
	collision.set_deferred("disabled", true)
	timer_create_new_enemy.stop()
	
func portal_process_start() -> void:
	visible = true
	collision.set_deferred("disabled", false)
	call_deferred("_add_child")
	timer_create_new_enemy.start()
	
func portal_free() -> void:
	for obj in list_enemy:
		obj._set_portal(null, 0)
	for obj in list_new_enemy:
		obj._set_portal(null, 0)
	list_enemy.clear()
	list_new_enemy.clear()
	portal_process_stop()
	if is_instance_valid(player):
		player.portal_free(self)
	portal_create_enemy_count+=portal_reload_enemy_increase
	probability_modificator = min(probability_modificator + probability_modificator_increase, probability_modificator_maximum)
	
func _get_object_size() -> float:
	return collision_shape.radius

func _on_timer_create_new_enemy_timeout() -> void:
	var enemy = create_enemy()
	var standart_material: StandardMaterial3D = StandardMaterial3D.new()
	standart_material.albedo_texture = enemy_two_wave_material	
	world.add_child(enemy)
	enemy.skeleton_surface.set_surface_override_material(0, standart_material)	
	enemy._set_portal(self, randf_range(0.0, 359.0))
	list_new_enemy.append(enemy)
	# grups enemy go yo player
	if list_new_enemy.size() == portal_create_new_enemy_groupe_count:
		for obj in list_new_enemy:
			list_enemy.erase(obj)
			obj._set_portal(null, 0)
		list_new_enemy.clear()
