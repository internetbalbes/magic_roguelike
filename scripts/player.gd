extends CharacterBody3D

# player's speed slow
const SPEED_SLOW = 2.5
# player's speed normal
const SPEED_NORMAL = 5.0
# player's speed fast
const SPEED_FAST = 10.0
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING
}

# player's initial state
var state = playerstate.IDLE

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  state == playerstate.IDLE &&  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			return
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
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			state = playerstate.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			state = playerstate.IDLE
	move_and_slide()
