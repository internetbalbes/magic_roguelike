extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready  var timer_danger = $timer_danger
@onready  var label_time = $label_time
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
	timer_danger.wait_time = portal_time_life
	timer_danger.start()
	call_deferred("_add_child")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var remaining_time = timer_danger.time_left
	label_time.text = "%02d" % remaining_time

func _on_timer_danger_timeout() -> void:
	for obj in list_enemy:
		obj.target = player
	queue_free()
	
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
