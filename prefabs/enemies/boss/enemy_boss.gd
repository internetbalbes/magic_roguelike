extends "res://prefabs/enemies/base/enemy_base.gd"


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var boss_model: Node3D = $kishi_model
@onready var animation_player: AnimationPlayer = $kishi_model/AnimationPlayer
@onready var timer_beat: Timer = $timer_beat
@onready var timer_run_to_player: Timer = $timer_run_to_player

# enemy's initial state
var state = enemystate.RUNNING_TO_PLAYER
# enemy's state
enum enemystate {
	BEATING,	# state fthrowimg
	RUNNING_TO_PLAYER,	# state runnning
	POOLING_TO_POINT,	# state pooling to point
	DEATHING	# state deathing
}

var target_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	enemy_speed = Globalsettings.enemy_param[enemy_type]["enemy_speed"]
	timer_beat.wait_time = Globalsettings.enemy_param[enemy_type]["time_to_beat"]
	var var_scale = Globalsettings.enemy_param[enemy_type]["enemy_transform_scale"]
	scale = Vector3(var_scale, var_scale, var_scale)
	navigation_agent.path_height_offset = -var_scale
	animation_player.animation_finished.connect(_on_animation_finished)	
	animation_player.get_animation("run").loop = true
	coldsteel_name = loot_cold_steels_list[randi_range(0, 1)]
	rune_name = "splash_targets_amount_increase"
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)	
	if !is_on_floor():
		return		
	elif state in [enemystate.BEATING]:
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)
		#look_at(player.global_transform.origin, Vector3.UP)
	elif state == enemystate.POOLING_TO_POINT:
		var direction = (enemy_pooling_to_point - global_transform.origin).normalized()
		# Poruszanie wroga w kierunku celu
		velocity = direction * enemy_speed
		move_and_slide()		
	elif state == enemystate.RUNNING_TO_PLAYER:
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu			
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			velocity = direction * enemy_speed
			move_and_slide()

func _get_point_on_circle_around_player() -> Vector3:
	var angle = deg_to_rad(randf_range(0.0, 180.0))
	var x = 1.5 * cos(angle)
	var z = 1.5 * sin(angle)
	return  Vector3(player.global_position.x - x, global_position.y, player.global_position.z - z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	_set_state_enemy(enemystate.BEATING)

func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_beat.stop()
		timer_run_to_player.stop()
		_set_state_enemy(enemystate.DEATHING)

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		_set_state_enemy(enemystate.BEATING)
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
		
func _set_position_freeze(pos: Vector3, freeze: bool) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(enemystate.POOLING_TO_POINT)
			enemy_pooling_to_point = pos
			timer_beat.stop()
			area.monitoring = false
			timer_run_to_player.stop()
		else:
			area.monitoring = true
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if !object:
		target_position = player.global_position
		navigation_agent.target_position = _get_point_on_circle_around_player()
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
	
func _set_state_enemy(value)->void:
	match value:
		enemystate.RUNNING_TO_PLAYER:
			state = enemystate.RUNNING_TO_PLAYER
			animation_player.play("run")
			timer_run_to_player.start()
		enemystate.BEATING:
			state = enemystate.BEATING
			animation_player.play("melee")
			timer_beat.start()
			timer_run_to_player.stop()
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")

func _on_timer_beat_timeout() -> void:
	if player_in_area:
		player.take_damage(Globalsettings.enemy_param[enemy_type]["damage"])	

func _on_timer_run_to_player_timeout() -> void:
	if target_position.distance_to(player.global_position) > 0.5:
		target_position = player.global_position
		navigation_agent.target_position = _get_point_on_circle_around_player()
