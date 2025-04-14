extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready var timer_portal_time_life = $timer_portal_time_life
@onready var label_time = $label_time
@export var prefabenemy : PackedScene
@export var player: CharacterBody3D
@export var world: Node3D

var portal_time_life = 60
var portal_create_enemy_count = 4
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
	var angle_shift = 300.0 / portal_create_enemy_count
	var angle = 0
	for i in range(0, portal_create_enemy_count, 1):
		var enemy = prefabenemy.instantiate()
		enemy.target = self
		enemy.player = player
		enemy.world = world
		enemy.enemy_angle_start = angle
		list_enemy.append(enemy)
		world.add_child(enemy)
		angle += angle_shift

func portal_process_stop() -> void:
	set_process(false)
	set_physics_process(false)
	timer_portal_time_life.stop()
	
func portal_process_start() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	timer_portal_time_life.wait_time = portal_time_life
	timer_portal_time_life.start()
	call_deferred("_add_child")	
	
func portal_free() -> void:
	visible = false
	for obj in list_enemy:
		obj.target = player
	timer_portal_time_life.wait_time = portal_time_life + timer_portal_time_life.time_left	
	portal_process_stop()	
	timer_portal_time_life.start()
	
func _on_timer_portal_time_life_timeout() -> void:
	if visible:
		# game over
		get_tree().call_deferred("reload_current_scene")
	else:
		# reinit portal
		world.list_portal_set_position.append(self)
		world.timer_height_scan_start()
