extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var boss_model: Node3D = $MeshInstance3D
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
# enemy's speed run or run
var enemy_speed = 1.0
var boss_damage = 1.0
var target_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed = config.get_value("enemy_boss", "enemy_speed", enemy_speed)
		timer_beat.wait_time = config.get_value("enemy_boss", "time_to_beat", timer_beat.wait_time)
		label_health.max_value = randi_range(1, config.get_value("enemy_boss", "enemy_max_health", label_health.max_value))
		probability_card =  config.get_value("enemy_boss", "probability_card", probability_card)
		probability_modificator =  config.get_value("enemy_boss", "probability_modificator", probability_modificator)
		boss_damage = config.get_value("enemy_boss", "boss_damage", 1)
		var var_scale = config.get_value("enemy_boss", "enemy_transform_scale",  1.0)
		boss_model.scale *= var_scale
		collision_areaseeing.radius = config.get_value("enemy_boss", "enemy_area_scan_player", 1.0)
		#config.save("res://settings.cfg")
	config = null

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

func _on_area_3d_body_exited(_body: Node3D) -> void:
	super._on_area_3d_body_exited(_body)
	target_position = player.global_position
	navigation_agent.target_position = _get_point_on_circle_around_player()
	_set_state_enemy(enemystate.RUNNING_TO_PLAYER)	
	
func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_beat.stop()
		timer_run_to_player.stop()
		_set_state_enemy(enemystate.DEATHING)

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
			timer_run_to_player.start()
		enemystate.BEATING:
			state = enemystate.BEATING
			timer_beat.start()
			timer_run_to_player.stop()
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
		enemystate.DEATHING:
			state = enemystate.DEATHING
			call_deferred("queue_free")

func _on_timer_beat_timeout() -> void:
	if player_in_area:
		player.take_damage(boss_damage)	

func _on_timer_run_to_player_timeout() -> void:
	if target_position.distance_to(player.global_position) > 0.5:
		target_position = player.global_position
		navigation_agent.target_position = _get_point_on_circle_around_player()
