extends StaticBody3D

@onready var omnolight = $OmniLight3D
@onready  var timer_danger = $timer_danger
@onready  var label_time = $label_time
@export var timer_wait : int = 60
@export var label_rotate_speed : int = 1

var flicker_intensity: float = 5
var flicker_speed: float = 10.0
var base_energy: float

func _ready() -> void:
	base_energy = omnolight.light_energy
	omnolight.omni_range = 10
	timer_danger.wait_time = timer_wait
	timer_danger.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var noise = randf_range(-flicker_intensity, flicker_intensity)
	omnolight.light_energy = base_energy + noise *flicker_speed * delta	
	var remaining_time = timer_danger.time_left
	label_time.text = "00:" + "%02d" % remaining_time
	label_time.rotate_y( label_rotate_speed * delta)

func _on_timer_danger_timeout() -> void: 
	queue_free()
