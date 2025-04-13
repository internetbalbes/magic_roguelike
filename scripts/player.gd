extends CharacterBody3D

@onready var camera = $Camera3D
@onready var label_health = $CanvasLayer/label_health
@onready var image_pointcatch = $CanvasLayer/image_pointcatch
@onready var timer_find_enemy = $timer_find_enemy
@export var prefabwaterball : PackedScene
@export var world: Node3D

# player's initial state
var state = playerstate.IDLE
var screen_pos = Vector2.ZERO
var camera_ray_params : PhysicsRayQueryParameters3D
# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING	# state jumping	
}
var player_max_health: int = 5
# player's speed normal
var player_speed_walk = 3
# player's speed jump
var player_jump_velocity = 3
# camer's sensitivity
var player_rotate_sensitivity = 0.085
var current_health: int = player_max_health

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_speed_walk = config.get_value("player", "player_speed_walk", player_speed_walk)
		player_max_health = config.get_value("player", "player_max_health", player_max_health)
		player_jump_velocity = config.get_value("player", "player_jump_velocity", player_jump_velocity)
		player_rotate_sensitivity = config.get_value("player", "player_rotate_sensitivity", player_rotate_sensitivity)
		#config.save("res://settings.cfg")
	config = null
	var rect = image_pointcatch.get_global_rect()
	screen_pos = rect.position + rect.size * 0.5
	camera_ray_params = PhysicsRayQueryParameters3D.new()
	camera_ray_params.exclude = []
	camera_ray_params.collision_mask = 64
	_on_health_changed(player_max_health)
	connect("health_changed", _on_health_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	timer_find_enemy.start()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			var waterball = prefabwaterball.instantiate()
			waterball.player = self
			world.add_child(waterball)
			waterball.global_transform.origin = camera_ray_params.from
			waterball.global_transform.basis = camera.global_transform.basis
	elif event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * player_rotate_sensitivity))

func _process(delta):		
	if !is_on_floor():
		# Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		state = playerstate.JUMPING
	else:
		if Input.is_action_pressed("jump"):
			velocity.y = player_jump_velocity
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * player_speed_walk
			velocity.z = direction.z * player_speed_walk
			state = playerstate.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, player_speed_walk)
			velocity.z = move_toward(velocity.z, 0, player_speed_walk)
			state = playerstate.IDLE
	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, player_max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)
	if !is_alive():
		get_tree().call_deferred("reload_current_scene")

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, player_max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func _on_timer_find_enemy_timeout() -> void:
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	var space = get_world_3d().direct_space_state
	camera_ray_params.from = ray_origin
	camera_ray_params.to = ray_origin + ray_dir * 1000.0	
	var result = space.intersect_ray(camera_ray_params)
	if result:
		image_pointcatch.modulate = Color(1, 0, 0)  # RGB (czerwony)
	else:
		image_pointcatch.modulate = Color(1, 1, 1)  # RGB (czerwony)
