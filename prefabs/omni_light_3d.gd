extends OmniLight3D

var flicker_intensity: float = 5
var flicker_speed: float = 10.0
var base_energy: float

func _ready() -> void:
	base_energy = light_energy
	omni_range = 5
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var noise = randf_range(-flicker_intensity, flicker_intensity)
	light_energy = base_energy + noise *flicker_speed * delta
