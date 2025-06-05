extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var animation_player: AnimationPlayer = $sky_mage_model/AnimationPlayer
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sphere_guard: Area3D = $sphere
@onready var timer_throw: Timer = $timer_throw
@export var skymag_sphere : PackedScene

# enemy's initial state
var state = enemystate.WALKING_PORTAL
# enemy's state
enum enemystate {
	WALKING_PORTAL,	# state walking around portal
	PRAYING,	# state praying
	THROWING,	# state fthrowimg
	POOLING_TO_POINT,	# state pooling to point
	FREEZING,	# state freezing to point
	DEATHING	# state deathing
}

# enemy pray's point
var target_point_pray = Vector3.ZERO

func _ready() -> void:	
	super._ready()
	enemy_speed = Globalsettings.enemy_param[enemy_type]["enemy_speed"]
	timer_throw.wait_time = Globalsettings.enemy_param[enemy_type]["time_to_throw"]
	var var_scale = Globalsettings.enemy_param[enemy_type]["enemy_transform_scale"]
	scale = Vector3(var_scale, var_scale, var_scale)
	navigation_agent.path_height_offset = -var_scale		
	sphere_guard.player = player
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("tornado").loop = true
	animation_player.get_animation("pray").loop = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
	elif state == enemystate.FREEZING:
		rest_freezing_time -= delta
		if rest_freezing_time < 0:
			_set_state_freezing(null, false)	
	elif state == enemystate.THROWING:
		rotate_towards_target(player.global_transform.origin, delta)
	elif state == enemystate.POOLING_TO_POINT:
		var direction = (enemy_pooling_to_point - global_transform.origin).normalized()
		# Poruszanie wroga w kierunku celu
		velocity = direction * enemy_speed
		move_and_slide()		
	elif state in [enemystate.WALKING_PORTAL]:		
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu			
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			velocity = direction * enemy_speed
			move_and_slide()
		else:
			target_point_pray = Vector3.ZERO
			timer_throw.start()
			_set_state_enemy(enemystate.PRAYING)

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif target_point_pray == Vector3.ZERO:
		var sphere = skymag_sphere.instantiate()
		sphere.player = player
		sphere.magic_type = "attack"
		world.add_child(sphere)
		timer_throw.start()
		_set_state_enemy(enemystate.PRAYING)
	else:
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _set_state_enemy(value)->void:
	match value:
		enemystate.WALKING_PORTAL:
			state = enemystate.WALKING_PORTAL
			animation_player.play("walk")
		enemystate.PRAYING:
			state = enemystate.PRAYING
			animation_player.play("pray")
		enemystate.THROWING:
			state = enemystate.THROWING
			animation_player.play("skycast")
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
		enemystate.FREEZING:
			state = enemystate.FREEZING
			animation_player.pause()
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")
			
func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		sphere_guard.monitoring = false	
		timer_throw.stop()
		_set_state_enemy(enemystate.DEATHING)
		
func _set_state_freezing(_state, freeze) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(_state)
			timer_throw.stop()
		elif target_point_pray == Vector3.ZERO:
			_set_state_enemy(enemystate.PRAYING)
		else:
			_set_state_enemy(enemystate.WALKING_PORTAL)	
	
func _set_pooling_to_point(pos: Vector3, freeze: bool) -> void:
	_set_state_freezing(enemystate.POOLING_TO_POINT, freeze)
	enemy_pooling_to_point = pos

func _set_freezing(_time):
	super._set_freezing(_time)
	_set_state_freezing(enemystate.FREEZING, true)
		
func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		var radius = Globalsettings.enemy_param[enemy_type]["enemy_distance_from_portal"] + randf_range(1, 10)
		var x = radius * cos(deg_to_rad(angle))
		var z = radius * sin(deg_to_rad(angle))
		target_point_pray = global_transform.origin + Vector3(x, 0, z)
		navigation_agent.target_position = target_point_pray
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _on_timer_throw_timeout() -> void:
	_set_state_enemy(enemystate.THROWING)
