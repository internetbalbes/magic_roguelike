extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var animation_player: AnimationPlayer = $sky_mage_model/AnimationPlayer
@onready var sphere_guard: Area3D = $sphere
@onready var timer_throw: Timer = $timer_throw
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
# enemy pray's point
var target_point_pray = Vector3.ZERO

func _ready() -> void:
	super._ready()
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_speed = config.get_value("enemy_skymage", "enemy_speed", enemy_speed)
		enemy_distance_from_portal = config.get_value("enemy_skymage", "enemy_distance_from_portal", enemy_distance_from_portal)
		timer_throw.wait_time = config.get_value("enemy_skymage", "time_to_throw", 5.0)
		label_health.max_value = randi_range(1, config.get_value("enemy_skymage", "enemy_max_health", label_health.max_value))
		probability_card =  config.get_value("enemy_skymage", "probability_card", probability_card)		
		var var_scale = config.get_value("enemy_skymage", "enemy_transform_scale",  1.0)
		scale = Vector3(var_scale, var_scale, var_scale)
		#config.save("res://settings.cfg")
	config = null
	sphere_guard.player = player
	sphere_guard.scale = scale
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("tornado").loop = true
	animation_player.get_animation("pray").loop = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
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

func _on_animation_finished(_anim_name: String) -> void:
	if !is_alive():
		call_deferred("queue_free")
	elif target_point_pray == Vector3.ZERO:
		var sphere = skymag_sphere.instantiate()
		sphere.player = player
		sphere.magic_type = "attack"
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
	super.take_damage(spell, buf, amount)
	if !is_alive():
		timer_throw.stop()
		_set_state_enemy(enemystate.DEATHING)
	
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
	
func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		var radius = enemy_distance_from_portal + randf_range(1, 10)
		var x = radius * cos(deg_to_rad(angle))
		var z = radius * sin(deg_to_rad(angle))
		target_point_pray = global_transform.origin + Vector3(x, 0, z)
		look_at(target_point_pray, Vector3.UP)
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _on_timer_throw_timeout() -> void:
	_set_state_enemy(enemystate.THROWING)
