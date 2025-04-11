extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var collision_shape: Shape3D = $Area3D/CollisionShape3D.shape
@onready var collision_enemy: Shape3D = $CollisionShape3D.shape
@onready var label_health: Label3D = $label_health
@onready var animation_player: AnimationPlayer = $enemy_model/AnimationPlayer
@onready var skeleton_bone_hand: BoneAttachment3D = $enemy_model/AuxScene/Node/Skeleton3D/BoneAttachment3D
@onready var timer_wait_set_trap: Timer = $timer_wait_set_trap
@onready var timer_set_trap: Timer = $timer_set_trap
@onready var timer_throw: Timer = $timer_throw
@export var speed = 2.0
@export var radius = 10.0
@export var target : Node3D
@export var player : CharacterBody3D
@export var segments = 36  # Liczba segmentów w okręgu
@export var time_wait_to_shoot = 2  # Liczba segmentów w okręgu
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene
@export var world: Node3D
@export var time_to_throw: float = 1
@export var time_to_set_trap: float = 2

var point_target = Vector3.ZERO
var player_in_area: bool = false
var max_health: int = 5
var current_health: int = max_health
var fireball: Area3D
var trap : StaticBody3D

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:	
	timer_wait_set_trap.wait_time = time_to_throw
	animation_player.animation_finished.connect(_on_animation_finished)
	_on_health_changed(max_health)
	connect("health_changed", _on_health_changed)
	collision_shape.radius = radius	
	global_transform.origin = target.global_transform.origin
	timer_wait_set_trap.wait_time = randf_range(5, 10)
	timer_wait_set_trap.start()
	_set_point_on_circle()
	animation_player.play("Walk")

func _process(delta: float) -> void:		
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		move_and_slide()
	elif animation_player.current_animation == "Throw":
		# Obracanie wroga w stronę celu	
		look_at(player.global_transform.origin, Vector3.UP)
	if animation_player.current_animation == "Walk" || animation_player.current_animation == "Run":
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
		fireball_create()
		player_in_area = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_area = false

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)	
	if !is_alive():
		if target != player:
			target.list_enemy.erase(self)
		label_health.visible = false	
		animation_player.play("Death")

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func fireball_create() -> void:
	if !fireball || fireball.get_parent() == world:
		fireball = prefabfireball.instantiate()
		skeleton_bone_hand.add_child(fireball)	
		fireball.global_position = skeleton_bone_hand.global_position
		fireball.scale *= 100
		fireball.player = player
		timer_throw.start()
		animation_player.play("Throw")

func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		queue_free()
	elif player_in_area:
		fireball_create()
	else:
		if target == player:
			animation_player.play("Run")
		else:
			animation_player.play("Walk")

func _on_timer_set_trap_timeout() -> void:
	trap = prefabtrap.instantiate()
	world.add_child(trap)
	trap.global_transform.origin = global_transform.origin - Vector3(0, collision_enemy.height / 2, 0)

func _on_timer_throw_timeout() -> void:
	fireball.reparent(world)	
	fireball.global_transform.origin = skeleton_bone_hand.global_transform.origin
	fireball.look_at(player.global_transform.origin, Vector3.UP)		
	fireball.fireball_time_life = 0.001	

func _on_timer_wait_set_trap_timeout() -> void:
	if animation_player.current_animation == "Walk" || animation_player.current_animation == "Run":		
		timer_set_trap.wait_time = time_to_set_trap
		timer_set_trap.start()
		animation_player.play("Putdown")
	else:
		timer_wait_set_trap.wait_time = 1
		timer_wait_set_trap.start()
