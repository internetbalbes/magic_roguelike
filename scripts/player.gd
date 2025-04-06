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
@export var image_pointcatch: TextureRect
@export var prefabwaterball : PackedScene
@export var prefabtrap : PackedScene

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING	# state jumping	
}

# player's initial state
var state = playerstate.IDLE

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("trap"):
		var trap = prefabtrap.instantiate()
		trap.player = self	
		get_tree().root.add_child(trap)
		trap.global_transform.origin = global_transform.origin
		trap.global_transform.basis = camera_raycast.global_transform.basis
	elif event is InputEventMouseButton:
		if  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			var waterball = prefabwaterball.instantiate()
			waterball.player = self
			get_tree().root.add_child(waterball)
			waterball.global_transform.origin = camera_raycast.global_transform.origin
			waterball.global_transform.basis = camera_raycast.global_transform.basis
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
	else: if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

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
