extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var collision_shape: Shape3D = $Area3D/CollisionShape3D.shape
@onready var label_health: Label3D = $label_health
@export var speed = 5.0
@export var radius = 20.0
@export var target : CharacterBody3D
@export var player : CharacterBody3D
@export var segments = 36  # Liczba segmentów w okręgu
@export var time_wait_to_shoot = 2  # Liczba segmentów w okręgu
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene
@export var world: Node3D

# player's speed jump
const JUMP_VELOCITY = 5

var point_target = Vector3.ZERO
var time_wait_set_trap = 0
var time_set_trap = 0
var jump = true
var is_set_trap = false
var shoot_next_time = 2
var time_wait_to_shoot_currenty = 0
var player_in_area: bool = false
var max_health: int = 5
var current_health: int = max_health

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:	
	_on_health_changed(max_health)
	connect("health_changed", _on_health_changed)
	collision_shape.radius = radius	
	global_transform.origin = target.global_transform.origin + Vector3.UP
	time_wait_set_trap = randf_range(5, 10)
	_set_point_on_circle()	

func _process(delta: float) -> void:
	if jump:
		velocity.y = JUMP_VELOCITY
		move_and_slide()
		jump = false
	elif !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		move_and_slide()
	else:
		if player_in_area:
			if time_wait_to_shoot_currenty > time_wait_to_shoot:
				shoot_to_player()
				time_wait_to_shoot_currenty = 0
			else:		
				time_wait_to_shoot_currenty += delta
		if !is_set_trap:
			if time_set_trap > time_wait_set_trap:
				var trap = prefabtrap.instantiate()
				world.add_child(trap)
				trap.global_transform.origin = global_transform.origin
				time_set_trap = 0
				is_set_trap = true
			else:
				time_set_trap += delta
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
			global_transform.origin = global_transform.origin + move_vector
		else:
			_set_point_on_circle()	
		
func _set_point_on_circle() -> void:
	var angle = randf_range(1, segments) * (2.0 * PI / segments)
	var x = radius * cos(angle)
	var z = radius * sin(angle)		
	point_target = target.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_area = true		

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_area = false

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)	

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func shoot_to_player():
	 # Tworzymy pocisk
	var fireball = prefabfireball.instantiate()
	world.add_child(fireball)
	fireball.player = player
	fireball.global_transform.origin = global_transform.origin + Vector3.UP
	# Obracanie wroga w stronę celu
	fireball.look_at(player.global_transform.origin, Vector3.UP)
	fireball.global_transform.origin += fireball.global_transform.basis*Vector3.FORWARD
