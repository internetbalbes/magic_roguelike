extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var area: Area3D = $Area3D
@onready var collision_area_shape: Shape3D = $Area3D/CollisionShape3D.shape
@onready var collision_shape: Shape3D = $CollisionShape3D.shape
@onready var icons_status: SubViewportContainer = $icons_status
@onready var label_health: ProgressBar = $icons_status/SubViewport/progressbar_health
@onready var label_buf: HBoxContainer = $icons_status/SubViewport/hboxcontainer_status
@onready var animation_player: AnimationPlayer = $enemy_model/AnimationPlayer
@onready var skeleton_bone_hand: BoneAttachment3D = $enemy_model/enemy_model/Skeleton3D/BoneAttachment3D
@onready var skeleton_surface: MeshInstance3D = $enemy_model/enemy_model/Skeleton3D/enemy
@onready var timer_throw: Timer = $timer_throw
@onready var timer_damage: Timer = $timer_damage
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene
@export var world: Node3D
@export var player : CharacterBody3D

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
 # cirkle's radius where patrol enemy
var enemy_radius_around_portal = 10.0
 # count segmentów in cirkle where patrol enemy
var count_segments_around_portal = 36 
# time in animation when enemy throw fireball
var time_to_throw: float = 1
# time in animation when enemy needs to set trap
var time_to_set_trap: float = 2
# time walk enemy from portal
var time_after_exit_portal: float = 1
# flag whith set that player in enemy's area
var player_in_area: bool = false
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
# point's coordinate enemy's mast pool
var enemy_pooling_to_point: Vector3 = Vector3.ZERO
#enemy's standard material when demage enemy
var standart_material_demage: StandardMaterial3D = StandardMaterial3D.new()
# array of Buf
var list_buf: Array
# array of all modificators
var list_modificators: Array = ["water_resist"]
# array of enemy modificators
var enemy_list_modificators: Array
# modificators value's probability
var probability_modificator = 50.0
# object portal spawn
var portal: Node3D
# enemy time's stand still
var time_stand_still = 0

func _ready() -> void:	
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed_walk = config.get_value("enemy", "enemy_speed_walk", enemy_speed_walk)
		enemy_speed_run = config.get_value("enemy", "enemy_speed_run", enemy_speed_run)
		enemy_radius_around_portal = config.get_value("enemy", "enemy_radius_around_portal", enemy_radius_around_portal)
		count_segments_around_portal = config.get_value("enemy", "count_segments_around_portal", count_segments_around_portal)
		time_to_throw = config.get_value("enemy", "time_to_throw", time_to_throw)
		time_to_set_trap = config.get_value("enemy", "time_to_set_trap", time_to_set_trap)		
		time_after_exit_portal = config.get_value("enemy", "time_after_exit_portal", time_after_exit_portal)
		timer_damage.wait_time = config.get_value("enemy", "enemy_time_is_damaged", timer_damage.wait_time)
		collision_area_shape.radius = config.get_value("enemy", "enemy_area_scan_player", enemy_radius_around_portal)
		label_health.max_value = randi_range(1, config.get_value("enemy", "enemy_max_health", label_health.max_value))
		probability_modificator =  config.get_value("enemy", "probability_modificator", probability_modificator)
		var var_scale = config.get_value("enemy", "enemy_transform_scale",  1.0)
		scale = Vector3(var_scale, var_scale, var_scale)
		#config.save("res://settings.cfg")
	config = null
	label_health.value = label_health.max_value
	skeleton_bone_hand.bone_name = "mixamorig_RightHand"
	area.monitoring = false
	standart_material_demage.albedo_color = Color(1.0, 1.0, 1.0)
	timer_throw.wait_time = time_to_throw
	animation_player.animation_finished.connect(_on_animation_finished)
	for modificator in list_modificators:
		if randi_range(1, 100) > probability_modificator:
			_add_modificator_to_list(modificator)
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
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	elif state == enemystate.DEATHING:
		pass
	elif state == enemystate.TRAPING:
		pass		
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
		if not navigation_agent.is_navigation_finished() && time_stand_still < 1:
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			#look_at(next_position, Vector3.UP)
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			velocity = direction * enemy_speed
			move_and_slide()
			navigation_agent.set_velocity_forced(velocity)
			time_stand_still += delta
			#global_transform.origin = global_transform.origin + move_vector
		else:
			time_stand_still = 0 
			if state in [enemystate.WALKING_PORTAL]:
				if navigation_agent.is_navigation_finished() || velocity.length() < 0.1:
					# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
					navigation_agent.target_position = _set_point_on_circle(enemy_angle_to_walk * (2.0 * PI / count_segments_around_portal))
					enemy_angle_to_walk = randf_range(1, count_segments_around_portal)
				time_stand_still = 0
			else:
				navigation_agent.target_position = player.global_position

func _set_point_on_circle(angle) -> Vector3:
	var x = enemy_radius_around_portal * cos(angle)
	var z = enemy_radius_around_portal * sin(angle)		
	return portal.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_area = true
		if state in [enemystate.WALKING_PORTAL, enemystate.RUNNING_TO_PLAYER]:	
			fireball_create()
		
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_area = false

func take_damage(spell, buf, amount: int):
	if state != enemystate.DEATHING:
		var is_demage = true
		match spell:
			"waterball": is_demage = !enemy_list_modificators.has("water_resist")
		if is_demage:
			label_health.value -= amount
			if !is_alive():
				player.add_card()
				if !timer_throw.is_stopped():
					timer_throw.stop()			
					if is_instance_valid(fireball):
						fireball.call_deferred("queue_free")
				area.monitoring = false
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)
				$sprite_status.set_deferred("visible", false)
				_set_state_enemy(enemystate.DEATHING)
				_timers_delete()
			else:
				if buf:
					_add_buf_to_list(buf)
				timer_damage.start()
			skeleton_surface.set_surface_override_material(0, standart_material_demage)

func is_alive() -> bool:
	return label_health.value > 0

func fireball_create() -> void:
	fireball = prefabfireball.instantiate()
	skeleton_bone_hand.add_child(fireball)	
	fireball.global_position = skeleton_bone_hand.global_position
	fireball.scale *= 100
	fireball.player = player
	timer_throw.start()
	_set_state_enemy(enemystate.THROWING)	

func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		call_deferred("queue_free")
	elif player_in_area:
		fireball_create()
	elif portal:
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		_set_state_enemy(enemystate.RUNNING_TO_PLAYER)

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

func rotate_towards_target(target_pos, delta):
	var current = global_transform.basis.get_euler()
	var direction = (global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = lerp_angle(current.y, target_yaw, delta * 5.0)
	global_transform.basis = Basis().rotated(Vector3.UP, current.y)

func _on_timer_after_exit_portal_timeout():
	timer_after_exit_portal.call_deferred("queue_free")
	area.monitoring = true
	timer_wait_set_trap.start()

func _on_timer_damage_timeout() -> void:
	if is_alive():
		skeleton_surface.set_surface_override_material(0, null)

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
	
func _get_object_size() -> float:
	return collision_shape.radius
	
func _get_object_height() -> float:
	return collision_shape.height	
	
func _set_portal(object: Node3D, angle: float) ->void:
	portal = object
	if portal:		
		enemy_angle_to_walk = angle * count_segments_around_portal / 360		
		var x = 2 * cos(deg_to_rad(angle))
		var z = 2 * sin(deg_to_rad(angle))	
		global_transform.origin = portal.global_transform.origin + Vector3(x, collision_shape.height, z)
		_set_state_enemy(enemystate.WALKING_PORTAL)
	else:
		area.monitoring = true
		if state == enemystate.WALKING_PORTAL:
			_set_state_enemy(enemystate.RUNNING_TO_PLAYER)
			_timers_delete()
	
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
		
func _add_buf_to_list(name_buf):
	if !list_buf.has(name_buf):
		var icon = TextureRect.new()		
		if name_buf == "wet":  
			icon.texture = load("res://sprites/wet_icon.png") as Texture2D
		icon.stretch_mode = TextureRect.STRETCH_KEEP	
		label_buf.add_child(icon)
		list_buf.append(name_buf)	
	
func _add_modificator_to_list(name_modificator):
	if !enemy_list_modificators.has(name_modificator):
		var icon = TextureRect.new()		
		if name_modificator == "water_resist":  
			icon.texture = load("res://sprites/water_resist_icon.png") as Texture2D
		icon.stretch_mode = TextureRect.STRETCH_KEEP	
		label_buf.add_child(icon)
		enemy_list_modificators.append(name_modificator)
		
func find_buf(name_buf)->bool:
	return list_buf.has(name_buf)
