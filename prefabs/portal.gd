extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready  var timer_danger = $timer_danger
@onready  var label_time = $label_time
@export var time_portal_life = 60
@export var prefabenemy : PackedScene
@export var enemy_count = 4
@export var player: CharacterBody3D
@export var world: Node3D

var list_enemy : Array
	
func _ready() -> void:
	timer_danger.wait_time = time_portal_life
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
	for i in range(0, enemy_count, 1):
		var enemy = prefabenemy.instantiate()
		enemy.target = self
		enemy.player = player
		enemy.world = world
		list_enemy.append(enemy)
		world.add_child(enemy)
