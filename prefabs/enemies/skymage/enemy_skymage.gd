extends CharacterBody3D

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var collision_shape: Shape3D = collision.shape
@onready var label_health: ProgressBar = $subviewport/progressbar_health
@onready var label_buf: HBoxContainer = $subviewport/hboxcontainer_status
@onready var animation_player: AnimationPlayer = $sky_mage_model/AnimationPlayer
@onready var timer_throw: Timer = $timer_throw
@export var world: Node3D
@export var player : CharacterBody3D
@export var skymag_sphere : PackedScene

var enemy_type = "skymage"
# enemy's initial state
var state = enemystate.WALKING_PORTAL
# enemy's state
enum enemystate {
	WALKING_PORTAL,	# state walking around portal
	PRAYING,	# state praying
	THROWING,	# state fthrowimg
	POOLING_TO_POINT,	# state pooling to point	
	DEATHING	# state deathing
}

 # enemy's walk
var enemy_speed = 0.55
 # distance from portal
var enemy_distance_from_portal = 10.0
# point's coordinate enemy's mast pool
var enemy_pooling_to_point: Vector3 = Vector3.ZERO
# array of Buf
var list_buf: Array
# array of all modificators
var list_modificators: Array = ["water_resist"]
# modificators value's probability
var probability_modificator = 50.0
# array of enemy modificators
var enemy_list_modificators: Array
# skymage sphere's time life
var skymage_sphere_time_life = 1.0
# skymage sphere's radius
var skymage_sphere_radius = 1.0
# skymage sphere's demage
var skymage_sphere_damage = 1
# cards value's probability
var probability_card = 50.0
# object portal spawn
var portal: Node3D
# enemy pray's point
var target_point_pray = Vector3.ZERO

func _ready() -> void:	
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed = config.get_value("enemy_skymage", "enemy_speed", enemy_speed)
		enemy_distance_from_portal = config.get_value("enemy_skymage", "enemy_distance_from_portal", enemy_distance_from_portal)
		timer_throw.wait_time = config.get_value("enemy_skymage", "time_to_throw", 5.0)
		label_health.max_value = randi_range(1, config.get_value("enemy_skymage", "enemy_max_health", label_health.max_value))
		probability_card =  config.get_value("enemy_skymage", "probability_card", probability_card)		
		skymage_sphere_time_life = config.get_value("enemy_skymage_sphere", "skymage_sphere_time_life", skymage_sphere_time_life)
		skymage_sphere_radius = config.get_value("enemy_skymage_sphere", "skymage_sphere_radius", skymage_sphere_radius)
		skymage_sphere_damage = config.get_value("enemy_skymage_sphere", "skymage_sphere_damage", skymage_sphere_damage)	
		var var_scale = config.get_value("enemy_skymage", "enemy_transform_scale",  1.0)
		scale = Vector3(var_scale, var_scale, var_scale)
		#config.save("res://settings.cfg")
	config = null	
	label_health.value = label_health.max_value
	animation_player.animation_finished.connect(_on_animation_finished)
	for modificator in list_modificators:
		if randi_range(1, 100) < probability_modificator:
			_add_modificator_to_list(modificator)
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("tornado").loop = true
	animation_player.get_animation("pray").loop = true

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	elif state == enemystate.PRAYING:
		pass		
	elif state == enemystate.DEATHING:
		pass
	elif state in [enemystate.THROWING]:
		rotate_towards_target(player.global_transform.origin, delta)
	elif state == enemystate.POOLING_TO_POINT:
		var direction = (enemy_pooling_to_point - global_transform.origin).normalized()
		# Poruszanie wroga w kierunku celu
		velocity = direction * enemy_speed
		move_and_slide()		
	elif state in [enemystate.WALKING_PORTAL]:
		# Sprawdzamy, czy agent ma jakąś ścieżkę do celu
		if global_position.distance_to(target_point_pray) > 0.5:
			# Obliczamy wektor kierunku do punktu
			var direction = target_point_pray - global_position
			# Znormalizuj wektor kierunku
			if direction.length() > 0:
				direction = direction.normalized()
			# Poruszanie wroga w kierunku celu			
			velocity.x = direction.x *  enemy_speed
			velocity.z = direction.z *  enemy_speed
			move_and_slide()	
		else:
			target_point_pray = Vector3.ZERO
			timer_throw.start()
			_set_state_enemy(enemystate.PRAYING)

func rotate_towards_target(target_pos, delta):
	var current = global_transform.basis.get_euler()
	var direction = (global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = lerp_angle(current.y, target_yaw, delta)
	global_transform.basis = Basis().rotated(Vector3.UP, current.y)
	
func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		call_deferred("queue_free")
	elif target_point_pray == Vector3.ZERO:		
		var sphere = skymag_sphere.instantiate()
		sphere.player = player
		sphere._set_param(skymage_sphere_time_life, skymage_sphere_radius, skymage_sphere_damage)
		world.add_child(sphere)
		timer_throw.start()
		_set_state_enemy(enemystate.PRAYING)
	else:
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _set_state_enemy(value)->void:
	match value:
		enemystate.WALKING_PORTAL:
			state = enemystate.WALKING_PORTAL
			animation_player.play("walk")
		enemystate.PRAYING:
			state = enemystate.PRAYING
			animation_player.play("pray")
		enemystate.THROWING:
			state = enemystate.THROWING
			animation_player.play("skycast")
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")
			
func take_damage(spell, buf, amount: int):
	if state != enemystate.DEATHING:
		var is_demage = true
		match spell:
			"waterball": is_demage = !enemy_list_modificators.has("water_resist")
		if is_demage:
			label_health.value -= amount
			if !is_alive():
				collision.set_deferred("disabled", true)
				if randi_range(1, 100) < probability_card:
					player.add_card()
				if !timer_throw.is_stopped():
					timer_throw.stop()
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)	
				$sprite_status.set_deferred("visible", false)
				_set_state_enemy(enemystate.DEATHING)
			elif buf:
				_add_buf_to_list(buf)

func is_alive() -> bool:
	return label_health.value > 0
	
func _set_position_freeze(pos: Vector3, freeze: bool) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(enemystate.POOLING_TO_POINT)
			enemy_pooling_to_point = pos
			timer_throw.stop()
		elif target_point_pray == Vector3.ZERO:
			_set_state_enemy(enemystate.PRAYING)
		else:
			_set_state_enemy(enemystate.WALKING_PORTAL)
					
func _get_object_size() -> float:
	return collision_shape.radius
	
func _get_object_height() -> float:
	return collision_shape.height	
	
func _set_portal(object: Node3D, angle: float) ->void:
	portal = object
	if portal:			
		global_transform.origin = object.global_transform.origin + Vector3(0, collision_shape.height/2, 0)
		var radius = enemy_distance_from_portal + randf_range(1, 10)
		var x = radius * cos(deg_to_rad(angle))
		var z = radius * sin(deg_to_rad(angle))
		target_point_pray = global_transform.origin + Vector3(x, 0, z)
		look_at(target_point_pray, Vector3.UP)
		_set_state_enemy(enemystate.WALKING_PORTAL)

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

func _on_timer_throw_timeout() -> void:
	_set_state_enemy(enemystate.THROWING)
