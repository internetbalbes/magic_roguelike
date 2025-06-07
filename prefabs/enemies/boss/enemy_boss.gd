extends "res://prefabs/enemies/base/enemy_base.gd"


@onready var boss_model: Node3D = $kishi_model
@onready var area_damage: MeshInstance3D = $area_damage

# enemy's state
enum local_enemystate {
	ROTATING = 100,	# state rotating
}

var count_direction_damage: int = 0

func _ready() -> void:
	super._ready()
	animation_player = $kishi_model/AnimationPlayer
	animation_melee_name = "melee_sword"
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
	elif state == local_enemystate.ROTATING:
		# Obracanie wroga w stronę celu	
		if rotate_towards_target(player.global_transform.origin, delta):
			if player_in_area:
				_set_state_enemy(enemystate.BEATING)
			else:
				_set_state_enemy(enemystate.POOLING_TO_POINT)

func _set_state_enemy(value)->void:
	super._set_state_enemy(value)
	match value:
		local_enemystate.ROTATING:
			state = local_enemystate.ROTATING
			timer_run_to_player.start()
			
func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	if state != local_enemystate.ROTATING:
		state = local_enemystate.ROTATING
		timer_run_to_player.stop()

func _on_area_3d_body_exited(_body: Node3D) -> void:
	super._on_area_3d_body_exited(_body)
	if state == local_enemystate.ROTATING:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
	
func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		state = local_enemystate.ROTATING
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

func _set_state_freezing(_state, freeze) -> void:
	super._set_state_freezing(_state, freeze)
	if state != enemystate.DEATHING:
		if !freeze:
			area.monitoring = true
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
					
func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if !object:
		_set_new_point_to_run()
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
	
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
