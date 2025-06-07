extends "res://prefabs/enemies/base/enemy_base.gd"

@onready var sphere_guard: Area3D = $sphere
@onready var timer_throw: Timer = $timer_throw
@onready var sky_mage_model_mesh: MeshInstance3D = $sky_mage_model/sky_mage_model/Skeleton3D/sky_mage
@export var skymag_sphere : PackedScene

# enemy's state
enum local_enemystate {
	PRAYING = 100	# state praying	
}

# enemy pray's point
var target_point_pray = Vector3.ZERO

func _ready() -> void:	
	super._ready()
	animation_player = $sky_mage_model/AnimationPlayer
	animation_melee_name = "skycast"
	timer_throw.wait_time = Globalsettings.enemy_param[enemy_type]["time_to_beat"]
	sphere_guard.player = player
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.get_animation("walk").loop = true
	animation_player.get_animation("tornado").loop = true
	animation_player.get_animation("pray").loop = true
	model_mesh = sky_mage_model_mesh

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !is_on_floor():
		return
	elif state == enemystate.BEATING:
		rotate_towards_target(player.global_transform.origin, delta)		
	elif state in [enemystate.WALKING_PORTAL]:		
		if navigation_agent.is_navigation_finished():
			target_point_pray = Vector3.ZERO
			timer_throw.start()
			_set_state_enemy(local_enemystate.PRAYING)

func _on_animation_finished(_anim_name: String) -> void:
	if state == enemystate.DEATHING:
		call_deferred("queue_free")
	elif target_point_pray == Vector3.ZERO:
		var sphere = skymag_sphere.instantiate()
		sphere.player = player
		sphere.magic_type = "attack"
		world.add_child(sphere)
		timer_throw.start()
		_set_state_enemy(local_enemystate.PRAYING)
	else:
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _set_state_enemy(value)->void:
	super._set_state_enemy(value)
	match value:
		local_enemystate.PRAYING:
			state = local_enemystate.PRAYING
			animation_player.play("pray")
			
func take_damage(spell, buf, amount: int):
	super.take_damage(spell, buf, amount)
	if !is_alive():
		sphere_guard.monitoring = false	
		timer_throw.stop()
		
func _set_state_freezing(_state, freeze) -> void:
	super._set_state_freezing(_state, freeze)
	if state != enemystate.DEATHING:
		if freeze:
			pass
		elif target_point_pray == Vector3.ZERO:
			_set_state_enemy(local_enemystate.PRAYING)
		else:
			_set_state_enemy(enemystate.WALKING_PORTAL)	
	
func _set_portal(object: Node3D, angle: float) ->void:
	super._set_portal(object, angle)
	if portal:
		var radius = Globalsettings.enemy_param[enemy_type]["enemy_distance_from_portal"] + randf_range(1, 10)
		var x = radius * cos(deg_to_rad(angle))
		var z = radius * sin(deg_to_rad(angle))
		target_point_pray = global_transform.origin + Vector3(x, 0, z)
		navigation_agent.target_position = target_point_pray
		_set_state_enemy(enemystate.WALKING_PORTAL)

func _on_timer_throw_timeout() -> void:
	_set_state_enemy(enemystate.BEATING)
