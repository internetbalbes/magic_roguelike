extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var player : CharacterBody3D
@export var speed = 5.0
@export var radius = 10.0
@onready var target : CharacterBody3D
@export var segments = 36  # Liczba segmentów w okręgu
var point_target = Vector3.ZERO

func _ready() -> void:
	_set_point_on_circle()	

func _process(delta: float) -> void:
	if !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		move_and_slide()
	else:
		# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
		navigation_agent.target_position = point_target
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			look_at(next_position, Vector3.UP)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			var move_vector = direction * speed * delta
			var new_pos = global_transform.origin + move_vector
			#if new_pos.y < global_transform.origin.y:
			#new_pos.y = global_transform.origin.y
			global_transform.origin = new_pos
			# Sprawdzanie, czy agent osiągnął cel
		else:
			_set_point_on_circle()
			
func _set_point_on_circle() -> void:
	var angle = randf_range(1, segments) * (2.0 * PI / segments)
	var x = radius * cos(angle)
	var z = radius * sin(angle)		
	point_target = target.global_transform.origin + Vector3(x, 0, z)
