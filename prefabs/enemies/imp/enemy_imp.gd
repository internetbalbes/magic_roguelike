extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $imp_model/AnimationPlayer
@onready var skeleton_bone_hand: BoneAttachment3D = $imp_model/imp_model/Skeleton3D/BoneAttachment3D
@onready var skeleton_surface: MeshInstance3D = $imp_model/imp_model/Skeleton3D/imp
@onready var timer_throw: Timer = $timer_throw
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene

# enemy's initial state
var state = enemystate.WALKING_PORTAL
# enemy's state
enum enemystate {
	WALKING_PORTAL,	# state walking around portal
	THROWING,	# state fthrowimg
	RUNNING_TO_PLAYER,	# state runnning
	POOLING_TO_POINT,	# state pooling to point
	TRAPING,	# state set trap
	DEATHING	# state deathing
}
# enemy's run
var enemy_speed_walk = 0.55
 # enemy's walk
var enemy_speed_run = 2.5
 # circle's radius where patrol enemy
var enemy_radius_around_portal = 10.0
 # count segmentów in cirkle where patrol enemy
var count_segments_around_portal = 36 
# time in animation when enemy throw fireball
var time_to_throw: float = 1
# time in animation when enemy needs to set trap
var time_to_set_trap: float = 2
# time walk enemy from portal
var time_after_exit_portal: float = 1
# Node fireball
var fireball: Area3D
# Node tram
var trap : Node3D
# object timer walk enemy from portal
var timer_after_exit_portal: Timer = Timer.new()
# object timeer after walk from portal when enemy needs to set trap
var timer_wait_set_trap: Timer = Timer.new()
# object timeer in animation when enemy needs to set trap
var timer_set_trap: Timer = Timer.new()
# enemy's speed walk or run
var enemy_speed = enemy_speed_walk
# angle enemy's to  walk
var enemy_angle_to_walk: float = 0

func _ready() -> void:
	super._ready()
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed_walk = config.get_value("enemy_imp", "enemy_speed_walk", enemy_speed_walk)
		enemy_speed_run = config.get_value("enemy_imp", "enemy_speed_run", enemy_speed_run)
		enemy_radius_around_portal = config.get_value("enemy_imp", "enemy_radius_around_portal", enemy_radius_around_portal)
		count_segments_around_portal = config.get_value("enemy_imp", "count_segments_around_portal", count_segments_around_portal)
		time_to_throw = config.get_value("enemy_imp", "time_to_throw", time_to_throw)
		time_to_set_trap = config.get_value("enemy_imp", "time_to_set_trap", time_to_set_trap)		
		time_after_exit_portal = config.get_value("enemy_imp", "time_after_exit_portal", time_after_exit_portal)
		collision_areaseeing.radius = config.get_value("enemy_imp", "enemy_area_scan_player", enemy_radius_around_portal)
		probability_card =  config.get_value("enemy_imp", "probability_card", probability_card)
		var var_scale = config.get_value("enemy_imp", "enemy_transform_scale",  1.0)
		scale = Vector3(var_scale, var_scale, var_scale)
		navigation_agent.path_height_offset = -var_scale
		#config.save("res://settings.cfg")
	config = null
	skeleton_bone_hand.bone_name = "mixamorig_RightHand"
	area.monitoring = false
	timer_throw.wait_time = time_to_throw
	animation_player.animation_finished.connect(_on_animation_finished)	
	#set timer set trap
	timer_set_trap.wait_time = time_to_set_trap
	timer_set_trap.one_shot = true
	timer_set_trap.timeout.connect(_on_timer_set_trap_timeout)
	add_child(timer_set_trap)
	#set timer wait trap	
	timer_wait_set_trap.wait_time = randf_range(5, 10)
	timer_wait_set_trap.one_shot = true
	timer_wait_set_trap.timeout.connect(_on_timer_wait_set_trap_timeout)
	add_child(timer_wait_set_trap)
	#set timer wait trap	
	timer_after_exit_portal.wait_time = time_after_exit_portal
	timer_after_exit_portal.one_shot = true
	timer_after_exit_portal.timeout.connect(_on_timer_after_exit_portal_timeout)
	add_child(timer_after_exit_portal)
	timer_after_exit_portal.start()
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("run").loop = true
	animation_player.get_animation("tornado").loop = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
	elif state in [enemystate.THROWING]:
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
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			velocity = direction * enemy_speed
			move_and_slide()
			navigation_agent.set_velocity_forced(velocity)
		else:
			if state in [enemystate.WALKING_PORTAL]:
				if portal && (navigation_agent.is_navigation_finished()):
					# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
					navigation_agent.target_position = _get_point_on_circle(enemy_angle_to_walk * (2.0 * PI / count_segments_around_portal))
					enemy_angle_to_walk = randf_range(1, count_segments_around_portal)
			else:
				navigation_agent.target_position = _get_point_on_circle_around_player()

func _get_point_on_circle_around_player() -> Vector3:
	var angle = deg_to_rad(randf_range(0.0, 180.0))
	var x = 3 * cos(angle)
	var z = 3 * sin(angle)		
	return player.global_position - Vector3(x, 0, z)
	
func _get_point_on_circle(angle) -> Vector3:
	var x = enemy_radius_around_portal * cos(angle)
	var z = enemy_radius_around_portal * sin(angle)		
	return portal.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	super._on_area_3d_body_entered(body)
	if state in [enemystate.WALKING_PORTAL, enemystate.RUNNING_TO_PLAYER]:	
		fireball_create()		

func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_throw.stop()			
		if is_instance_valid(fireball):
			fireball.call_deferred("queue_free")
		_set_state_enemy(enemystate.DEATHING)
		_timers_delete()		

func fireball_create() -> void:
	fireball = prefabfireball.instantiate()
	skeleton_bone_hand.add_child(fireball)	
	fireball.global_position = skeleton_bone_hand.global_position
	fireball.scale *= 1000
	fireball.player = player
	timer_throw.start()
	_set_state_enemy(enemystate.THROWING)	

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif player_in_area:
		fireball_create()
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

func _on_timer_throw_timeout() -> void:
	fireball.reparent(world)	
	fireball.global_transform.origin = skeleton_bone_hand.global_transform.origin	
	fireball.look_at(player.global_transform.origin, Vector3.UP)		
	fireball.collision_set_enabled()

func _on_timer_wait_set_trap_timeout() -> void:
	if state in [enemystate.WALKING_PORTAL]:
		timer_wait_set_trap.call_deferred("queue_free")	
		timer_set_trap.start()
		_set_state_enemy(enemystate.TRAPING)		
	else:
		timer_wait_set_trap.wait_time = 1
		timer_wait_set_trap.start()

func _on_timer_after_exit_portal_timeout():
	timer_after_exit_portal.call_deferred("queue_free")
	area.monitoring = true
	timer_wait_set_trap.start()

func _set_position_freeze(pos: Vector3, freeze: bool) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(enemystate.POOLING_TO_POINT)
			enemy_pooling_to_point = pos
			if is_instance_valid(fireball):
				fireball.call_deferred("queue_free")
			timer_throw.stop()
			if is_instance_valid(timer_wait_set_trap):
				timer_wait_set_trap.stop()
			elif is_instance_valid(timer_set_trap):
				timer_set_trap.stop()
			area.monitoring = false
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
		enemy_angle_to_walk = angle * count_segments_around_portal / 360		
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		area.monitoring = true
		if state == enemystate.WALKING_PORTAL:
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
			_timers_delete()
			navigation_agent.target_position = _get_point_on_circle_around_player()
	
func _set_state_enemy(value)->void:
	match value:
		enemystate.RUNNING_TO_PLAYER:
			state = enemystate.RUNNING_TO_PLAYER
			animation_player.play("run")
			enemy_speed = enemy_speed_run
		enemystate.WALKING_PORTAL:
			state = enemystate.WALKING_PORTAL
			animation_player.play("walk")
			enemy_speed = enemy_speed_walk
		enemystate.THROWING:
			state = enemystate.THROWING
			animation_player.play("throw")
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
			enemy_speed = enemy_speed_run
		enemystate.TRAPING:
			state = enemystate.TRAPING
			animation_player.play("putdown")
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")
	
func _timers_delete()->void:
	if is_instance_valid(timer_after_exit_portal):
		timer_after_exit_portal.call_deferred("queue_free")
	if is_instance_valid(timer_wait_set_trap):
		timer_wait_set_trap.call_deferred("queue_free")
	if is_instance_valid(timer_set_trap):
		timer_set_trap.call_deferred("queue_free")
