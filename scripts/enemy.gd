extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var area: Area3D = $Area3D
@onready var collision_area_shape: Shape3D = $Area3D/CollisionShape3D.shape
@onready var collision_shape: Shape3D = $CollisionShape3D.shape
@onready var label_health: Label3D = $label_health
@onready var animation_player: AnimationPlayer = $enemy_model/AnimationPlayer
@onready var skeleton_bone_hand: BoneAttachment3D = $enemy_model/AuxScene/Node/Skeleton3D/BoneAttachment3D
@onready var skeleton_surface: MeshInstance3D = $enemy_model/AuxScene/Node/Skeleton3D/Alpha_Surface
@onready var skeleton_joints: MeshInstance3D = $enemy_model/AuxScene/Node/Skeleton3D/Alpha_Joints
@onready var timer_throw: Timer = $timer_throw
@onready var timer_damage: Timer = $timer_damage
@export var prefabtrap : PackedScene
@export var prefabfireball : PackedScene
@export var world: Node3D
@export var player : CharacterBody3D

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
# ppoint navigation where to walk enemy
var point_target = Vector3.ZERO
# flag whith set that player in enemy's area
var player_in_area: bool = false
# enemy's maxhealth
var enemy_max_health: int = 5
# enemy's current health
var current_health: int = enemy_max_health
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
# angle enemy's start
var enemy_angle_start: float = 0
# node enemy's hand
var skeleton_standart_material: StandardMaterial3D = StandardMaterial3D.new()
# Place on which enemy orientation 
var target : Node3D
# array of Buf
var list_buf: Array
# plater's camera
var camera : Camera3D

# procedure change enemy's health
signal health_changed(new_health)

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
		enemy_max_health =  randi_range(1, config.get_value("enemy", "enemy_max_health", enemy_max_health))
		#config.save("res://settings.cfg")
	config = null
	camera = player.get_node("Camera3D")
	current_health = enemy_max_health
	area.monitoring = false
	skeleton_standart_material.albedo_color = Color(1.0, 1.0, 1.0)
	timer_throw.wait_time = time_to_throw
	animation_player.animation_finished.connect(_on_animation_finished)
	_on_health_changed(current_health)
	connect("health_changed", _on_health_changed)	
	global_transform.origin = target.global_transform.origin + Vector3(0, collision_shape.height / 2, 0)
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
	#set start enemy's coordinate
	_set_point_on_circle((enemy_angle_start * count_segments_around_portal / 360) * (2.0 * PI / count_segments_around_portal))
	animation_player.play("Walk")

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	elif animation_player.current_animation == "Throw":
		# Obracanie wroga w stronę celu	
		rotate_towards_target(player.global_transform.origin, delta)		
	if animation_player.current_animation == "Walk" || animation_player.current_animation == "Run":
		# Zaktualizowanie pozycji agenta nawigacji, aby poruszał się w kierunku celu
		navigation_agent.target_position = point_target
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			# Obracanie wroga w stronę celu
			rotate_towards_target(next_position, delta)
			# Obliczanie wektora kierunku
			var direction = (next_position - global_transform.origin).normalized()
			# Poruszanie wroga w kierunku celu
			var move_vector = direction * enemy_speed * delta
			global_transform.origin = global_transform.origin + move_vector
		else:
			if target == player:
				point_target = player.global_position
			else:
				_set_point_on_circle(randf_range(1, count_segments_around_portal) * (2.0 * PI / count_segments_around_portal))	
	elif !animation_player.active:
		move_and_slide()
		
func _set_point_on_circle(angle) -> void:
	var x = enemy_radius_around_portal * cos(angle)
	var z = enemy_radius_around_portal * sin(angle)		
	point_target = target.global_transform.origin + Vector3(x, 0, z)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_area = true
		
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_area = false

func take_damage(buf, amount: int):
	if animation_player.current_animation != "Death":
		if buf:
			_add_buf_to_list(buf)
		current_health -= amount
		current_health = clamp(current_health, 0, enemy_max_health)  # Zapobiega przekroczeniu zakresu zdrowia
		emit_signal("health_changed", current_health)	
		if !is_alive():
			area.monitoring = false
			if target != player:
				target.list_enemy.erase(self)
			label_health.visible = false	
			animation_player.play("Death")
			_timers_delete()
		timer_damage.start()
		skeleton_surface.set_surface_override_material(0, skeleton_standart_material)
		skeleton_joints.set_surface_override_material(0, skeleton_standart_material)

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, enemy_max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func fireball_create() -> void:
	fireball = prefabfireball.instantiate()
	skeleton_bone_hand.add_child(fireball)	
	fireball.global_position = skeleton_bone_hand.global_position
	fireball.scale *= 100
	fireball.player = player
	timer_throw.start()
	animation_player.play("Throw")

func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		call_deferred("queue_free")
	elif animation_player.active:	
		if player_in_area:
			fireball_create()
		else:
			if target == player:
				animation_player.play("Run")
			else:
				animation_player.play("Walk")

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
	if animation_player.current_animation in ["Walk", "Run"]:
		timer_wait_set_trap.call_deferred("queue_free")	
		timer_set_trap.start()
		animation_player.play("Putdown")
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
		skeleton_joints.set_surface_override_material(0, null)

func _set_position_freeze(pos: Vector3, freeze: bool) -> void:
	animation_player.active = !freeze
	if freeze:
		if is_instance_valid(timer_after_exit_portal):
			timer_after_exit_portal.stop()
		else:
			area.monitoring = false
			if is_instance_valid(fireball):
				fireball.call_deferred("queue_free")
			timer_throw.stop()
			if is_instance_valid(timer_wait_set_trap):
				timer_wait_set_trap.stop()
			elif is_instance_valid(timer_set_trap):
				timer_set_trap.stop()
		global_transform.origin = pos
		animation_player.stop()
	else:		
		animation_player.play("Walk")
		if is_instance_valid(timer_after_exit_portal):
			timer_after_exit_portal.start()
		else:
			area.monitoring = true
			if timer_wait_set_trap:
				timer_wait_set_trap.start()		
			elif timer_set_trap:		
				timer_set_trap.start()
	
func _get_object_size() -> float:
	return collision_shape.radius
	
func _get_object_height() -> float:
	return collision_shape.height	
	
func _set_target(object: Node3D) ->void:
	target = object
	if target == player:
		enemy_speed = enemy_speed_run
		area.monitoring = true
		_timers_delete()		
	else:
		enemy_speed = enemy_speed_walk

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
			icon.texture = load("res://textures/icon_drop.png") as Texture2D
		icon.stretch_mode = TextureRect.STRETCH_KEEP	
		$status_icons/SubViewport/HBoxContainer.add_child(icon)
		list_buf.append(name_buf)	
	
func find_buf(name_buf)->bool:
	return list_buf.has(name_buf)
