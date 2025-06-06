extends "res://prefabs/enemies/base/enemy_base.gd"


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var boss_model: Node3D = $kishi_model
@onready var animation_player: AnimationPlayer = $kishi_model/AnimationPlayer
@onready var timer_run_to_player: Timer = $timer_run_to_player
@onready var area_damage: MeshInstance3D = $area_damage


# enemy's initial state
var state = enemystate.RUNNING_TO_PLAYER
# enemy's state
enum enemystate {
	BEATING,	# state fthrowimg
	RUNNING_TO_PLAYER,	# state runnning
	POOLING_TO_POINT,	# state pooling to point
	FREEZING,	# state freezing to point
	DEATHING	# state deathing
}

var count_direction_damage: int = 0
var target_position: Vector3 = Vector3.ZERO
var animation_melee_name = "melee_sword"

func _ready() -> void:
	super._ready()
	enemy_speed = Globalsettings.enemy_param[enemy_type]["enemy_speed"]
	var var_scale = Globalsettings.enemy_param[enemy_type]["enemy_transform_scale"]
	scale = Vector3(var_scale, var_scale, var_scale)
	navigation_agent.path_height_offset = -var_scale
	animation_player.animation_finished.connect(_on_animation_finished)	
	animation_player.get_animation("run").loop = true
	coldsteel_name = loot_cold_steels_list[randi_range(0, 1)]
	rune_name = "splash_targets_amount_increase"
	_area_param_damage_param()
	_animation_player_frame_connect(animation_player, "melee", animation_melee_name, Globalsettings.enemy_param[enemy_type]["time_to_beat"], "_on_time_beat")	
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)	
	if !is_on_floor():
		return		
	elif state == enemystate.FREEZING:
		rest_freezing_time -= delta
		if rest_freezing_time < 0:
			_set_state_freezing(null, false)
	elif state == enemystate.BEATING:
		pass	
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
	if state != enemystate.BEATING:
		_set_state_enemy(enemystate.BEATING)

func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_run_to_player.stop()
		_set_state_enemy(enemystate.DEATHING)

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		_set_state_enemy(enemystate.BEATING)
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

func _set_state_freezing(_state, freeze) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(_state)
			area.monitoring = false
			timer_run_to_player.stop()
		else:
			area.monitoring = true
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
					
func _set_pooling_to_point(pos: Vector3, freeze: bool) -> void:
	_set_state_freezing(enemystate.POOLING_TO_POINT, freeze)
	enemy_pooling_to_point = pos

func _set_freezing(_time):
	super._set_freezing(_time)
	_set_state_freezing(enemystate.FREEZING, true)
	
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
			animation_player.play(animation_melee_name)
			timer_run_to_player.stop()
			# Obracanie wroga w stronę celu	
			rotate_towards_target(player.global_transform.origin, 0.01)
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
		enemystate.FREEZING:
			state = enemystate.FREEZING
			animation_player.pause()
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")

func _on_time_beat() -> void:
	if player_in_area:		
		var to_target = (global_position - player.global_position).normalized()
		for i in range(0, count_direction_damage, 1):
			var angle_between = rad_to_deg(global_transform.basis.z.rotated(Vector3.UP,  deg_to_rad(i * 360.0 / count_direction_damage)).angle_to(to_target))
			if abs(angle_between) <= Globalsettings.enemy_param[enemy_type]["setor_damage"]:
				player.take_damage(Globalsettings.enemy_param[enemy_type]["damage"])
	_area_param_damage_param()
		
func _area_param_damage_param():
		count_direction_damage = randi_range(1, Globalsettings.enemy_param[enemy_type]["count_direction_damage"])
		var distance =	randf_range(Globalsettings.enemy_param[enemy_type]["radius_sector_damage_min"], Globalsettings.enemy_param[enemy_type]["radius_sector_damage_max"])
		collision_areaseeing.radius = distance
		(area_damage.mesh as PlaneMesh).size = Vector2.ONE * 2.0 * collision_areaseeing.radius
		var mat = area_damage.get_material_override() 
		mat.set_shader_parameter("sector_count", count_direction_damage)
		mat.set_shader_parameter("sector_angle", Globalsettings.enemy_param[enemy_type]["setor_damage"])
	
func _on_timer_run_to_player_timeout() -> void:
	if target_position.distance_to(player.global_position) > 0.5:
		target_position = player.global_position
		navigation_agent.target_position = _get_point_on_circle_around_player()
