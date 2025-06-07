extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var zombi_model: Node3D = $zombie_model
@onready var zombi_model_mesh: MeshInstance3D = $zombie_model/zombie_model/Skeleton3D/zombie

# angle enemy's to  walk
var enemy_angle_to_walk: float = 0

func _ready() -> void:
	super._ready()
	animation_player = $zombie_model/AnimationPlayer
	animation_melee_name = "melee_sword"
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("run").loop = true
	_animation_player_frame_connect(animation_player, "melee", animation_melee_name, Globalsettings.enemy_param[enemy_type]["time_to_beat"], "_on_time_beat")
	model_mesh = zombi_model_mesh
	#coldsteel_name = loot_cold_steels_list[randi_range(0, 1)]
	#rune_name = "splash_targets_amount_increase"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)	
	if !is_on_floor():
		return		
	elif state in [enemystate.BEATING]:
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)
	elif state == enemystate.WALKING_PORTAL && portal && (navigation_agent.is_navigation_finished()):
		# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
		navigation_agent.target_position = _get_point_on_circle( Globalsettings.enemy_param[enemy_type]["enemy_radius_around_portal"], enemy_angle_to_walk * (2.0 * PI /  Globalsettings.enemy_param["common"]["count_segments_around_portal"]))
		enemy_angle_to_walk = randf_range(1,  Globalsettings.enemy_param["common"]["count_segments_around_portal"])

func _set_state_freezing(_state, freeze) -> void:
	super._set_state_freezing(_state, freeze)
	if state != enemystate.DEATHING:
		if freeze:
			pass
		else:
			area.monitoring = true
			if portal:
				_set_state_enemy(enemystate.WALKING_PORTAL)
			else:
				_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
				
func _get_point_on_circle(radius, angle) -> Vector3:
	var x = radius * cos(angle)
	var z = radius * sin(angle)		
	return portal.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	if state in [enemystate.WALKING_PORTAL, enemystate.RUNNING_TO_PLAYER]:
		_set_state_enemy(enemystate.BEATING)

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		_set_state_enemy(enemystate.BEATING)
	elif portal:
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		enemy_angle_to_walk = angle *  Globalsettings.enemy_param["common"]["count_segments_around_portal"] / 360
		_set_state_enemy(enemystate.WALKING_PORTAL)
	elif state == enemystate.WALKING_PORTAL:
		_set_new_point_to_run()
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
	
func _on_time_beat() -> void:
	if player_in_area:
		player.take_damage( Globalsettings.enemy_param[enemy_type]["damage"])
