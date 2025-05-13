extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $zombie_model/AnimationPlayer
@onready var skeleton_surface: MeshInstance3D = $zombie_model/zombie_model/Skeleton3D/zombie
@onready var timer_beat: Timer = $timer_beat
@onready var timer_run_to_player: Timer = $timer_run_to_player

var enemy_type = "zombie"
# enemy's initial state
var state = enemystate.WALKING_PORTAL
# enemy's state
enum enemystate {
	WALKING_PORTAL,	# state walking around portal
	BEATING,	# state fthrowimg
	RUNNING_TO_PLAYER,	# state runnning
	POOLING_TO_POINT,	# state pooling to point
	DEATHING	# state deathing
}
# enemy's run
var enemy_speed_walk = 0.55
 # enemy's walk
var enemy_speed_run = 2.5
 # cirkle's radius where patrol enemy
var enemy_radius_around_portal = 10.0
 # count segmentów in cirkle where patrol enemy
var count_segments_around_portal = 36 
# enemy's speed walk or run
var enemy_speed = enemy_speed_walk
# angle enemy's to  walk
var enemy_angle_to_walk: float = 0
var zombie_damage = 1.0

func _ready() -> void:
	super._ready()
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed_walk = config.get_value("enemy_zombie", "enemy_speed_walk", enemy_speed_walk)
		enemy_speed_run = config.get_value("enemy_zombie", "enemy_speed_run", enemy_speed_run)
		enemy_radius_around_portal = config.get_value("enemy_zombie", "enemy_radius_around_portal", enemy_radius_around_portal)
		count_segments_around_portal = config.get_value("enemy_zombie", "count_segments_around_portal", count_segments_around_portal)
		timer_beat.wait_time = config.get_value("enemy_zombie", "time_to_beat", timer_beat.wait_time)
		collision_areaseeing.radius = config.get_value("enemy_zombie", "enemy_area_scan_player", 1.0)
		label_health.max_value = randi_range(1, config.get_value("enemy_zombie", "enemy_max_health", label_health.max_value))
		probability_card =  config.get_value("enemy_zombie", "probability_card", probability_card)
		probability_modificator =  config.get_value("enemy_zombie", "probability_modificator", probability_modificator)
		zombie_damage = config.get_value("enemy_zombie", "zombie_damage", 1)
		var var_scale = config.get_value("enemy_zombie", "enemy_transform_scale",  zombie_damage)
		scale = Vector3(var_scale, var_scale, var_scale)
		#config.save("res://settings.cfg")
	config = null
	animation_player.animation_finished.connect(_on_animation_finished)	
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("run").loop = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
	elif state == enemystate.DEATHING:
		pass
	elif state in [enemystate.BEATING]:
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)
		#look_at(player.global_transform.origin, Vector3.UP)
	elif state == enemystate.POOLING_TO_POINT:
		var direction = (enemy_pooling_to_point - global_transform.origin).normalized()
		# Poruszanie wroga w kierunku celu
		velocity = direction * enemy_speed
		move_and_slide()		
	elif state in [enemystate.WALKING_PORTAL,  enemystate.RUNNING_TO_PLAYER]:
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if not navigation_agent.is_navigation_finished() && time_stand_still < 3:
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			#look_at(next_position, Vector3.UP)
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			velocity = direction * enemy_speed
			move_and_slide()
			time_stand_still += delta
			#global_transform.origin = global_transform.origin + move_vector
		else:
			time_stand_still = 0 
			if state in [enemystate.WALKING_PORTAL]:
				if portal && (navigation_agent.is_navigation_finished() || velocity.length() < 0.1):
					# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
					navigation_agent.target_position = _set_point_on_circle(enemy_angle_to_walk * (2.0 * PI / count_segments_around_portal))
					enemy_angle_to_walk = randf_range(1, count_segments_around_portal)
			else:
				navigation_agent.target_position = player.global_position
	
func _set_point_on_circle(angle) -> Vector3:
	var x = enemy_radius_around_portal * cos(angle)
	var z = enemy_radius_around_portal * sin(angle)		
	return portal.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	if player_in_area && state in [enemystate.WALKING_PORTAL, enemystate.RUNNING_TO_PLAYER]:
		_set_state_enemy(enemystate.BEATING)

func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_beat.stop()
		timer_run_to_player.stop()
		_set_state_enemy(enemystate.DEATHING)

func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		call_deferred("queue_free")
	elif player_in_area:
		_set_state_enemy(enemystate.BEATING)
	elif portal:
		_set_state_enemy(enemystate.WALKING_PORTAL)
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
			if portal:
				_set_state_enemy(enemystate.WALKING_PORTAL)
			else:
				_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		enemy_angle_to_walk = angle * count_segments_around_portal / 360
		_set_state_enemy(enemystate.WALKING_PORTAL)
	elif state == enemystate.WALKING_PORTAL:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
		navigation_agent.target_position = player.global_position
		timer_run_to_player.start()
	
func _set_state_enemy(value)->void:
	match value:
		enemystate.RUNNING_TO_PLAYER:
			state = enemystate.RUNNING_TO_PLAYER
			animation_player.play("run")
			enemy_speed = enemy_speed_run
			timer_run_to_player.start()
		enemystate.WALKING_PORTAL:
			state = enemystate.WALKING_PORTAL
			animation_player.play("walk")
			enemy_speed = enemy_speed_walk
		enemystate.BEATING:
			state = enemystate.BEATING
			animation_player.play("melee")
			timer_beat.start()
			timer_run_to_player.stop()
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
			enemy_speed = enemy_speed_run
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")

func _on_timer_beat_timeout() -> void:
	if player_in_area:
		player.take_damage(zombie_damage)	

func _on_timer_run_to_player_timeout() -> void:
	if navigation_agent.target_position.distance_to(player.global_position) > 1.0:
		navigation_agent.target_position = player.global_position
		
