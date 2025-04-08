extends CharacterBody3D

# player's speed slow
const SPEED_SLOW = 2.5
# player's speed normal
const SPEED_NORMAL = 5.0
# player's speed fast
const SPEED_FAST = 10.0
# player's speed jump
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1

@onready var camera = $Camera3D
@onready var camera_raycast = $Camera3D/camera_raycast
@onready var label_health = $CanvasLayer/label_health
@onready var image_pointcatch = $CanvasLayer/image_pointcatch
@export var prefabwaterball : PackedScene
@export var world: Node3D

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING	# state jumping	
}

# player's initial state
var state = playerstate.IDLE
var max_health: int = 5
var current_health: int = max_health

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:
	_on_health_changed(max_health)
	connect("health_changed", _on_health_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			var waterball = prefabwaterball.instantiate()
			waterball.player = self
			world.add_child(waterball)
			waterball.global_transform.origin = camera_raycast.global_transform.origin + camera_raycast.global_transform.basis * Vector3.FORWARD
			waterball.global_transform.basis = camera_raycast.global_transform.basis
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))

func _process(delta):
	if !is_on_floor():
		# Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		state = playerstate.JUMPING
	else:
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		var speed = SPEED_NORMAL	
		if Input.is_action_pressed("sneek"):
			speed = SPEED_SLOW
		elif Input.is_action_pressed("run"):
			speed = SPEED_FAST	
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			state = playerstate.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			state = playerstate.IDLE
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_groups().size() > 0:
		if body.get_groups()[0] == "trap":
			body.queue_free()
			take_damage(1)  # Zadaj 10 obrażeń graczowi

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)
	if current_health <= 0:
		get_tree().call_deferred("reload_current_scene")

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia
