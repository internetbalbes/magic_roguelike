extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var skeleton_bone_hand: BoneAttachment3D = $imp_model/imp_model/Skeleton3D/BoneAttachment3D
@onready var skeleton_surface: MeshInstance3D = $imp_model/imp_model/Skeleton3D/imp
@onready var imp_model_mesh: MeshInstance3D = $imp_model/imp_model/Skeleton3D/imp
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene

# enemy's state
enum local_enemystate {
	TRAPING = 100	# state set trap	
}
# Node tram
var trap : Node3D
# object timer walk enemy from portal
var timer_after_exit_portal: Timer = Timer.new()
# object timeer after walk from portal when enemy needs to set trap
var timer_wait_set_trap: Timer = Timer.new()
# object timeer in animation when enemy needs to set trap
var timer_set_trap: Timer = Timer.new()
# angle enemy's to  walk
var enemy_angle_to_walk: float = 0

func _ready() -> void:
	super._ready()
	animation_player = $imp_model/AnimationPlayer
	animation_melee_name = "throw_ball"	
	skeleton_bone_hand.bone_name = "mixamorig_RightHand"
	area.monitoring = false
	animation_player.animation_finished.connect(_on_animation_finished)	
	#set timer set trap
	timer_set_trap.wait_time = Globalsettings.enemy_param[enemy_type]["time_to_set_trap"]
	timer_set_trap.one_shot = true
	timer_set_trap.timeout.connect(_on_timer_set_trap_timeout)
	add_child(timer_set_trap)
	#set timer wait trap	
	timer_wait_set_trap.wait_time = randf_range(5, 10)
	timer_wait_set_trap.one_shot = true
	timer_wait_set_trap.timeout.connect(_on_timer_wait_set_trap_timeout)
	add_child(timer_wait_set_trap)
	#set timer wait trap	
	timer_after_exit_portal.wait_time = Globalsettings.enemy_param[enemy_type]["time_after_exit_portal"]
	timer_after_exit_portal.one_shot = true
	timer_after_exit_portal.timeout.connect(_on_timer_after_exit_portal_timeout)
	add_child(timer_after_exit_portal)
	timer_after_exit_portal.start()
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("run").loop = true
	animation_player.get_animation("tornado").loop = true
	_animation_player_frame_connect(animation_player, "throw", animation_melee_name, Globalsettings.enemy_param[enemy_type]["time_to_beat"], "_on_time_beat")	
	model_mesh = imp_model_mesh

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
	elif state == enemystate.BEATING:
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)
	elif state in [enemystate.WALKING_PORTAL]:
		if portal && (navigation_agent.is_navigation_finished()):
			# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
			navigation_agent.target_position = _get_point_on_circle(enemy_angle_to_walk * (2.0 * PI / Globalsettings.enemy_param["common"]["count_segments_around_portal"]))
			enemy_angle_to_walk = randf_range(1, Globalsettings.enemy_param["common"]["count_segments_around_portal"])
		else:
			_set_new_point_to_run()

func _get_point_on_circle(angle) -> Vector3:
	var x = Globalsettings.enemy_param[enemy_type]["enemy_radius_around_portal"] * cos(angle)
	var z = Globalsettings.enemy_param[enemy_type]["enemy_radius_around_portal"] * sin(angle)		
	return portal.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	if state in [enemystate.WALKING_PORTAL, enemystate.RUNNING_TO_PLAYER]:	
		_set_state_enemy(enemystate.BEATING)		

func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		_set_state_enemy(enemystate.DEATHING)
		_timers_delete()		

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		_set_state_enemy(enemystate.BEATING)		
	elif portal:
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
		_timers_delete()

func _on_timer_set_trap_timeout() -> void:
	timer_set_trap.call_deferred("queue_free")	
	trap = prefabtrap.instantiate()
	trap.player = player
	world.add_child(trap)
	var direction = Vector3(0, collision_shape.height / 2, 0.5).normalized()
	trap.global_transform.origin = global_transform.origin - direction

func _on_time_beat() -> void:
	var fireball = prefabfireball.instantiate()
	fireball.scale *= 2
	fireball.player = player
	world.add_child(fireball)	
	fireball.global_transform.origin = skeleton_bone_hand.global_transform.origin
	fireball.look_at(player.raycast.global_transform.origin - Vector3(0.0, 0.5, 0.0), Vector3.UP)		
	fireball.collision_set_enabled()

func _on_timer_wait_set_trap_timeout() -> void:
	if state in [enemystate.WALKING_PORTAL]:
		timer_wait_set_trap.call_deferred("queue_free")	
		timer_set_trap.start()
		_set_state_enemy(local_enemystate.TRAPING)		
	else:
		timer_wait_set_trap.wait_time = 1
		timer_wait_set_trap.start()

func _on_timer_after_exit_portal_timeout():
	timer_after_exit_portal.call_deferred("queue_free")
	area.monitoring = true
	timer_wait_set_trap.start()

func _set_state_freezing(_state, freeze) -> void:
	super._set_state_freezing(_state, freeze)
	if state != enemystate.DEATHING:
		if freeze:
			if is_instance_valid(timer_wait_set_trap):
				timer_wait_set_trap.stop()
			elif is_instance_valid(timer_set_trap):
				timer_set_trap.stop()
		else:
			if portal:
				_set_state_enemy(enemystate.WALKING_PORTAL)
				if is_instance_valid(timer_after_exit_portal):
					timer_after_exit_portal.start()
				else:
					area.monitoring = true
					if timer_wait_set_trap:
						timer_wait_set_trap.start()		
					elif timer_set_trap:		
						timer_set_trap.start()
				_set_state_enemy(enemystate.WALKING_PORTAL)
			else:
				area.monitoring = true
				_set_state_enemy(enemystate.RUNNING_TO_PLAYER)	
	
func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		enemy_angle_to_walk = angle * Globalsettings.enemy_param["common"]["count_segments_around_portal"] / 360
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		area.monitoring = true
		if state == enemystate.WALKING_PORTAL:
			_set_new_point_to_run()
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
			_timers_delete()
	
func _set_state_enemy(value)->void:
	super._set_state_enemy(value)
	match value:
		local_enemystate.TRAPING:
			state = local_enemystate.TRAPING
			animation_player.play("putdown")
		
func _timers_delete()->void:
	if is_instance_valid(timer_after_exit_portal):
		timer_after_exit_portal.call_deferred("queue_free")
	if is_instance_valid(timer_wait_set_trap):
		timer_wait_set_trap.call_deferred("queue_free")
	if is_instance_valid(timer_set_trap):
		timer_set_trap.call_deferred("queue_free")
