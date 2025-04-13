extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var area: Area3D = $Area3D
@onready var collision_shape: Shape3D = $Area3D/CollisionShape3D.shape
@onready var collision_enemy: Shape3D = $CollisionShape3D.shape
@onready var label_health: Label3D = $label_health
@onready var animation_player: AnimationPlayer = $enemy_model/AnimationPlayer
@onready var skeleton_bone_hand: BoneAttachment3D = $enemy_model/AuxScene/Node/Skeleton3D/BoneAttachment3D
@onready var timer_wait_set_trap: Timer = $timer_wait_set_trap
@onready var timer_set_trap: Timer = $timer_set_trap
@onready var timer_throw: Timer = $timer_throw
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene
@export var world: Node3D
@export var target : Node3D
@export var player : CharacterBody3D

var enemy_speed_walk = 0.55
var enemy_speed_run = 2.5
var enemy_radius_around_portal = 10.0
var count_segments_around_portal = 36  # Liczba segmentów w okręgu
var time_wait_to_shoot = 2
var time_to_throw: float = 1
var time_to_set_trap: float = 2
var time_after_exit_portal: float = 1
var point_target = Vector3.ZERO
var player_in_area: bool = false
var max_health: int = 5
var current_health: int = max_health
var fireball: Area3D
var trap : Node3D
var timer_after_exit_portal: Timer = Timer.new()
var enemy_speed = enemy_speed_walk
var enemy_angle_start: float = 0

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:	
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed_walk = config.get_value("enemy", "enemy_speed_walk", enemy_speed_walk)
		enemy_speed_run = config.get_value("enemy", "enemy_speed_run", enemy_speed_run)
		enemy_radius_around_portal = config.get_value("enemy", "enemy_radius_around_portal", enemy_radius_around_portal)
		count_segments_around_portal = config.get_value("enemy", "count_segments_around_portal", count_segments_around_portal)
		time_wait_to_shoot = config.get_value("enemy", "time_wait_to_shoot", time_wait_to_shoot)
		time_to_throw = config.get_value("enemy", "time_to_throw", time_to_throw)
		time_to_set_trap = config.get_value("enemy", "time_to_set_trap", time_to_set_trap)		
		time_after_exit_portal = config.get_value("enemy", "time_after_exit_portal", time_after_exit_portal)
		#config.save("res://settings.cfg")
	config = null
	timer_throw.wait_time = time_to_throw
	animation_player.animation_finished.connect(_on_animation_finished)
	_on_health_changed(max_health)
	connect("health_changed", _on_health_changed)
	collision_shape.radius = enemy_radius_around_portal	
	global_transform.origin = target.global_transform.origin + Vector3(0, collision_enemy.height / 2, 0)
	timer_wait_set_trap.wait_time = randf_range(5, 10)
	timer_wait_set_trap.start()
	_set_point_on_circle((enemy_angle_start * count_segments_around_portal / 360) * (2.0 * PI / count_segments_around_portal))
	animation_player.play("Walk")
	timer_after_exit_portal.wait_time = time_after_exit_portal
	timer_after_exit_portal.one_shot = true
	timer_after_exit_portal.timeout.connect(_on_timer_guard_timeout)
	add_child(timer_after_exit_portal)
	timer_after_exit_portal.start()

func _process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		move_and_slide()
	elif animation_player.current_animation == "Throw":
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)		
	if animation_player.current_animation == "Walk" || animation_player.current_animation == "Run":
		# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
		navigation_agent.target_position = point_target
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			var move_vector = direction * enemy_speed * delta
			global_transform.origin = global_transform.origin + move_vector
		else:
			if target == player:
				point_target = player.global_transform.origin
			else:
				_set_point_on_circle(randf_range(1, count_segments_around_portal) * (2.0 * PI / count_segments_around_portal))	
		
func _set_point_on_circle(angle) -> void:
	var x = enemy_radius_around_portal * cos(angle)
	var z = enemy_radius_around_portal * sin(angle)		
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
		timer_set_trap.stop()
		timer_throw.stop()
		timer_wait_set_trap.stop()		
		queue_free()
	elif player_in_area:
		fireball_create()
	else:
		if target == player:
			enemy_speed = enemy_speed_run
			animation_player.play("Run")
		else:
			enemy_speed = enemy_speed_walk
			animation_player.play("Walk")

func _on_timer_set_trap_timeout() -> void:
	trap = prefabtrap.instantiate()
	trap.player = player
	world.add_child(trap)
	var direction = Vector3(0, collision_enemy.height / 2, 0.5).normalized()
	trap.global_transform.origin = global_transform.origin - direction

func _on_timer_throw_timeout() -> void:
	fireball.reparent(world)	
	fireball.global_transform.origin = skeleton_bone_hand.global_transform.origin	
	fireball.look_at(player.global_transform.origin, Vector3.UP)		
	fireball.collision_set_enabled()

func _on_timer_wait_set_trap_timeout() -> void:
	if animation_player.current_animation in ["Walk", "Run"]:
		timer_set_trap.wait_time = time_to_set_trap
		timer_set_trap.start()
		animation_player.play("Putdown")
	else:
		timer_wait_set_trap.wait_time = 1
		timer_wait_set_trap.start()

func rotate_towards_target(target_pos, delta):
	var current = global_transform.basis.get_euler()
	var direction = (global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = lerp_angle(current.y, target_yaw, delta * 5.0)
	global_transform.basis = Basis().rotated(Vector3.UP, current.y)

func _on_timer_guard_timeout():
	timer_after_exit_portal.queue_free()
	area.connect("body_entered", _on_area_3d_body_entered)
