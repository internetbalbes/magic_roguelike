extends CharacterBody3D

# player's initial state
var state = playerstate.IDLE
# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING	# state jumping		
}

func _ready() -> void:		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * Globalsettings.player_param["player_rotate_sensitivity"]))
	
func _physics_process(delta: float) -> void:
	if !is_on_floor():
		# Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		state = playerstate.JUMPING		
	else:		
		if Input.is_action_pressed("jump"):
			velocity.y = Globalsettings.player_param["player_jump_velocity"]
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * Globalsettings.player_param["player_speed_walk"]
			velocity.z = direction.z * Globalsettings.player_param["player_speed_walk"]
			state = playerstate.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, Globalsettings.player_param["player_speed_walk"])
			velocity.z = move_toward(velocity.z, 0, Globalsettings.player_param["player_speed_walk"])
			state = playerstate.IDLE
	move_and_slide()


func _on_portal_to_game_body_entered(_body: Node3D) -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/world.tscn")
