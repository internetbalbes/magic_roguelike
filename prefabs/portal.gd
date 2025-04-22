extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var mesh_body : MeshInstance3D = $MeshInstance3D
@onready var mesh_fire : MeshInstance3D = $MeshInstance3D2
@onready var collision_shape : Shape3D = collision.shape
@export var prefabenemy : PackedScene
@export var player: CharacterBody3D
@export var world: Node3D

#generation count enemies on a map
var portal_create_enemy_count = 4
#generation list enemies on a map
var list_enemy : Array
	
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:		
		portal_create_enemy_count = config.get_value("portal", "portal_create_enemy_count", portal_create_enemy_count)
		#config.save("res://settings.cfg")
	config = null		

func _add_child():
	var angle_shift = 330.0 / portal_create_enemy_count
	var angle = 0
	for i in range(0, portal_create_enemy_count, 1):
		var enemy = prefabenemy.instantiate()
		enemy._set_target(self)
		enemy.player = player
		enemy.world = world
		enemy.enemy_angle_start = angle
		list_enemy.append(enemy)
		world.add_child(enemy)
		angle += angle_shift

func portal_process_stop() -> void:
	mesh_body.visible = false
	mesh_fire.visible = false
	collision.set_deferred("disabled", true)
	
func portal_process_start() -> void:
	mesh_body.visible = true
	mesh_fire.visible = true	
	collision.set_deferred("disabled", false)
	call_deferred("_add_child")	
	
func portal_free() -> void:	
	for obj in list_enemy:
		obj.target = player
	list_enemy.clear()		
	portal_process_stop()
	if is_instance_valid(player):
		player.portal_free(self)
	
func _get_object_size() -> float:
	return collision_shape.radius
