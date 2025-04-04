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

@onready var waterball = $Camera3D/waterball
@export var label_tip : Label
@export var image_pointcatch: TextureRect

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING,	# state jumping
	FINDFIRE	# state find fire
}

# player's initial state
var state = playerstate.IDLE
# helping for user
var tipson: bool = false

func _ready() -> void:
	label_tip.text = "Left mouse button to shoot a fire ball"
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		tipson = config.get_value("common", "tip", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  state == playerstate.IDLE &&  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			waterball.enabled = true
			state = playerstate.FINDFIRE
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
	else: if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _process(delta):
	if state == playerstate.FINDFIRE:
		if waterball.is_colliding():
			var body = waterball.get_collider()
			print(body.name)
			if body.get_parent().name == "fires":
				label_tip.visible = false
				image_pointcatch.visible = false
				body.queue_free()			
		state = playerstate.IDLE
		waterball.enabled = false		
	elif !is_on_floor():
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


func _on_area_tip_body_entered(body: Node3D) -> void:
	if body.get_parent().name == "fires":
		label_tip.visible = tipson
		image_pointcatch.visible = true


func _on_area_tip_body_exited(body: Node3D) -> void:
	if body.get_parent().name == "fires":
		label_tip.visible = false
		image_pointcatch.visible = false
