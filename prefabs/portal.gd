extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready var timer_portal_time_life = $timer_portal_time_life
@onready var label_time = $label_time
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var mesh_body : MeshInstance3D = $MeshInstance3D
@onready var mesh_fire : MeshInstance3D = $MeshInstance3D2
@onready var collision_shape : Shape3D = collision.shape
@export var prefabenemy : PackedScene
@export var player: CharacterBody3D
@export var world: Node3D

#portal's time life
var portal_time_life = 60
#generation count enemies on a map
var portal_create_enemy_count = 4
#generation list enemies on a map
var list_enemy : Array
	
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		portal_time_life = config.get_value("portal", "portal_time_life", portal_time_life)
		portal_create_enemy_count = config.get_value("portal", "portal_create_enemy_count", portal_create_enemy_count)
		#config.save("res://settings.cfg")
	config = null	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var remaining_time = timer_portal_time_life.time_left
	label_time.text = "%02d" % remaining_time
	
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
	#set_process(false)
	set_physics_process(false)
	mesh_body.visible = false
	mesh_fire.visible = false
	collision.set_deferred("disabled", true)
	timer_portal_time_life.stop()
	
func portal_process_start() -> void:
	mesh_body.visible = true
	mesh_fire.visible = true	
	collision.set_deferred("disabled", false)
	#set_process(true)
	set_physics_process(true)
	timer_portal_time_life.wait_time = portal_time_life
	timer_portal_time_life.start()
	call_deferred("_add_child")	
	
func portal_free() -> void:	
	for obj in list_enemy:
		obj.target = player
	list_enemy.clear()	
	timer_portal_time_life.wait_time = portal_time_life + timer_portal_time_life.time_left	
	portal_process_stop()	
	timer_portal_time_life.start()
	
func _on_timer_portal_time_life_timeout() -> void:
	if mesh_body.visible:
		# game over
		get_tree().call_deferred("reload_current_scene")
	else:
		# reinit portal
		world.list_portal_set_position.append(self)
		world.timer_height_scan_start()

func _get_object_size() -> float:
	return collision_shape.radius
