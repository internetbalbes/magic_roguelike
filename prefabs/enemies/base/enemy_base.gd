extends CharacterBody3D

@onready var collision: CollisionShape3D = $CollisionShape3D
@export var world: Node3D
@export var player : CharacterBody3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# enemy's initial state
var state = enemystate.WALKING_PORTAL
# enemy's state
enum enemystate {
	WALKING_PORTAL, # state walking_portal
	BEATING,	# state fthrowimg
	RUNNING_TO_PLAYER,	# state runnning
	POOLING_TO_POINT,	# state pooling to point
	FREEZING,	# state freezing to point
	DEATHING	# state deathing
}

var timer_run_to_player: Timer = Timer.new()
var animation_player: AnimationPlayer
var animation_melee_name = ""
var enemy_pivot: Node3D
var enemy_pivot_modificator: Node3D
var enemy_pivot_buf: Node3D
var area: Area3D
# collision are seeing scan for player
var collision_areaseeing: Shape3D
# enemy's collision 
var collision_shape: Shape3D
# flag whith set that player in enemy's area
var player_in_area: bool = false
# point's coordinate enemy's mast pool
var enemy_pooling_to_point: Vector3 = Vector3.ZERO
# array of Buf
var list_buf: Array
# array of enemy modificators
var enemy_list_modificators: Array
# object portal spawn
var portal: Node3D
var enemy_type = ""
var enemy_effect : Node3D
var label_health_value = 0
var enemy_speed = 0.0
var coldsteel_name = ""
var rune_name = ""
var loot_cold_steels_list = ["one_handed_sword", "one_handed_axe"]
var freezing_time: float = 0.0
var rest_freezing_time = freezing_time
var target_position: Vector3 = Vector3.ZERO
var model_mesh: MeshInstance3D

func _ready() -> void:
	timer_run_to_player.timeout.connect(_on_timer_run_to_player_timeout)
	timer_run_to_player.wait_time = 0.1	
	add_child(timer_run_to_player)
	if has_node("area_seeing"):
		area = get_node("area_seeing")
		collision_areaseeing = area.get_node("CollisionShape3D").shape
		collision_areaseeing.radius = Globalsettings.enemy_param[enemy_type]["enemy_area_scan_player"]
		area.body_entered.connect(_on_area_3d_body_entered)
		area.body_exited.connect(_on_area_3d_body_exited)	
	collision_shape = collision.shape
	label_health_value = Globalsettings.enemy_param[enemy_type]["label_health_max_value"]
	if randi_range(1, 100) <  Globalsettings.enemy_param["common"]["probability_modificator"]:
		var keys = Globalsettings.enemy_list_modificators.keys()
		_add_modificator_to_list(keys[randi_range(0, keys.size()-1)])
	var var_scale = Globalsettings.enemy_param[enemy_type]["enemy_transform_scale"]
	scale = Vector3(var_scale, var_scale, var_scale)
	navigation_agent.path_height_offset = -var_scale	

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	elif state == enemystate.FREEZING:
		rest_freezing_time -= delta
		if rest_freezing_time < 0:
			_set_state_freezing(null, false)
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

func _on_area_3d_body_entered(_body: Node3D) -> void:
	player_in_area = true
		
func _on_area_3d_body_exited(_body: Node3D) -> void:
	player_in_area = false
	
func create_enemy_pivot():
	if !enemy_pivot:
		enemy_pivot = load("res://prefabs/enemies/base/enemy_pivot.tscn").instantiate()
		add_child(enemy_pivot)
		enemy_pivot_modificator = enemy_pivot.get_node("modificator")
		enemy_pivot_modificator.visible = false
		enemy_pivot_buf =  enemy_pivot.get_node("buf")
		enemy_pivot_buf.visible = false	

func get_enemy_effect():
	if !enemy_effect:
		enemy_effect = load("res://prefabs/enemies/base/enemy_effect.tscn").instantiate()
		add_child(enemy_effect)
		enemy_effect.blood_drop.emitting = false
		enemy_effect.blood_drop.one_shot = true
	return enemy_effect

func take_damage_beat(spell, buf, amount, _position):
	get_enemy_effect().blood_drop.position = to_local(_position)
	enemy_effect.blood_drop.restart()
	take_damage(spell, buf, amount)
	enemy_effect.blood_spot.modulate.a = 1.0
	enemy_effect.blood_spot.visible = true
	var tween_blood = enemy_effect.blood_spot.create_tween()
	tween_blood.tween_property(enemy_effect.blood_spot, "modulate:a", 0.0, 5.0).set_trans(Tween.TRANS_LINEAR)
	tween_blood.tween_callback(func():
		enemy_effect.blood_spot.visible = false
	)
	spawn_blood_on_floor()

func _set_pooling_to_point(pos: Vector3, freeze: bool) -> void:
	_set_state_freezing(enemystate.POOLING_TO_POINT, freeze)
	enemy_pooling_to_point = pos
	
func _set_state_freezing(_state, freeze) -> void:
	if state != enemystate.DEATHING:
		if freeze:
			_set_state_enemy(_state)
			if area:
				area.monitoring = false
			timer_run_to_player.stop()
		else:
			model_mesh.material_override = null

func _set_freezing(_time):
	freezing_time = _time
	rest_freezing_time = freezing_time	
	model_mesh.material_override = load("res://resource/freeze_shader_material.tres")
	model_mesh.material_override.set_shader_parameter("albedo_texture", Globalsettings.enemy_param[enemy_type]["enemy_texture"])
	_set_state_freezing(enemystate.FREEZING, true)

func take_damage(spell, buf, amount: int):
	if is_alive():
		var is_demage = true
		if enemy_list_modificators.size() > 0 && spell != "coldsteel":
			if !enemy_list_modificators.has("magic_resist"):
				match spell:
					"waterball": is_demage = !enemy_list_modificators.has("water_resist")
			else:
				is_demage = false
		if is_demage:
			label_health_value -= amount
			if !is_alive():
				if enemy_pivot_modificator:
					enemy_pivot_modificator.get_parent().visible = false
				collision.set_deferred("disabled", true)
				if coldsteel_name != "":
					player.create_coldsteel_pivot(self, coldsteel_name, 0)
				if rune_name != "":
					player.create_rune_pivot(self, rune_name, 180)
				if randi_range(1, 100) <  Globalsettings.enemy_param[enemy_type]["probability_card"]:
					player.add_card()
				if area:
					area.monitoring = false
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)
				timer_run_to_player.stop()
				_set_state_enemy(enemystate.DEATHING)		
			elif buf:
				_add_buf_to_list(buf) 

func _set_portal(object: Node3D, _angle: float) ->void:
	portal = object
	if portal:
		global_transform.origin = portal.global_transform.origin + Vector3(0, collision_shape.height/2, 0)

func is_alive() -> bool:
	return label_health_value > 0

func rotate_towards_target(target_pos, delta):
	var current = global_transform.basis.get_euler()
	var direction = (global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = lerp_angle(current.y, target_yaw, delta * 30.0)
	var _scale = global_transform.basis.get_scale()
	var _rotation = Basis().rotated(Vector3.UP, current.y)
	global_transform.basis = _rotation.scaled(_scale)
	return abs(current.y - target_yaw) < 0.01
	
func _get_object_size() -> float:
	return collision_shape.radius
	
func _get_object_height() -> float:
	return collision_shape.height	
		
func _add_buf_to_list(name_buf):
	if !list_buf.has(name_buf):
		create_enemy_pivot()
		var node_buf = enemy_pivot_buf.duplicate()
		node_buf.mesh.material.albedo_texture =  Globalsettings.enemy_list_bufs[name_buf].texture
		node_buf.mesh.material.emission_texture =  Globalsettings.enemy_list_bufs[name_buf].texture
		node_buf.visible = true
		node_buf.position.y = _get_object_height() / 2 * 1.1
		enemy_pivot.add_child(node_buf)
		list_buf.append(name_buf)	
	
func _add_modificator_to_list(name_modificator):
	create_enemy_pivot()
	var node_modificator = enemy_pivot_modificator.duplicate()
	node_modificator.mesh.material.albedo_texture =  Globalsettings.enemy_list_modificators[name_modificator].texture
	node_modificator.mesh.material.emission_texture =  Globalsettings.enemy_list_modificators[name_modificator].texture	
	node_modificator.visible = true
	enemy_pivot.add_child(node_modificator)
	enemy_list_modificators.append(name_modificator)
		
func find_buf(name_buf)->bool:
	return list_buf.has(name_buf)
	
func object_is_freezed() ->bool:
	return !enemy_list_modificators.has("magic_resist")

func _on_area_seeing_body_entered(_body: Node3D) -> void:
	player_in_area = true

func _on_area_seeing_body_exited(_body: Node3D) -> void:
	player_in_area = false
			
func spawn_blood_on_floor():
	var decal = enemy_effect.blood_spot.duplicate()		
	# Ustaw rozmiar decal'a
	decal.size = Vector3(Globalsettings.enemy_param[enemy_type]["size_blood_on_floor"])
	decal.modulate.a = 1.0
	# Dodaj do sceny
	world.add_child(decal)
	# Ustaw pozycję minimalnie nad podłożem (by uniknąć z-fightingu)
	decal.global_transform.origin = global_position - Vector3(0.0, _get_object_height() / 2, 0.0) + Vector3.UP * 0.05	
	# Ustaw rotację, by był równoległy do podłogi (Y-up)
	decal.rotation_degrees = Vector3(0, randf() * 360.0, 0)  # losowy obrót dla różnorodności
	decal.visible = true
	var tween = decal.create_tween()
	tween.tween_property(decal, "modulate:a", 0.0, 10.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(Callable(decal, "queue_free"))	
		
func _animation_player_frame_connect(anim_player, anim_name, new_anim_name, anim_time_at_frame, anim_callback):
	var anim_lib = anim_player.get_animation_library("")
	var anim = anim_player.get_animation(anim_name).duplicate(true)
	anim_lib.add_animation(new_anim_name, anim)
	var track_index = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track_index, get_path())
	anim.track_insert_key(track_index, anim_time_at_frame, {"method": anim_callback, "args": []})

func _set_state_enemy(value)->void:
	match value:
		enemystate.RUNNING_TO_PLAYER:
			state = enemystate.RUNNING_TO_PLAYER
			animation_player.play("run")
			enemy_speed = Globalsettings.enemy_param[enemy_type]["enemy_speed_run"]
			timer_run_to_player.start()
		enemystate.WALKING_PORTAL:
			state = enemystate.WALKING_PORTAL
			animation_player.play("walk")
			enemy_speed =  Globalsettings.enemy_param[enemy_type]["enemy_speed_walk"]
		enemystate.BEATING:
			state = enemystate.BEATING
			animation_player.play(animation_melee_name)
			timer_run_to_player.stop()
		enemystate.POOLING_TO_POINT:
			state = enemystate.POOLING_TO_POINT
			animation_player.play("tornado")
			enemy_speed =  Globalsettings.enemy_param[enemy_type]["enemy_speed_run"]
		enemystate.FREEZING:
			state = enemystate.FREEZING
			animation_player.pause()	
		enemystate.DEATHING:
			state = enemystate.DEATHING
			animation_player.play("death")

func _get_point_on_circle_around_player() -> Vector3:
	var angle = deg_to_rad(randf_range(0.0, 180.0))
	var x = 1.5 * cos(angle)
	var z = 1.5 * sin(angle)
	return  Vector3(player.global_position.x - x, global_position.y, player.global_position.z - z)
		
func _on_timer_run_to_player_timeout() -> void:
	if target_position.distance_to(player.global_position) > 0.5:
		_set_new_point_to_run()

func _set_new_point_to_run() -> void:
	target_position = player.global_position
	navigation_agent.target_position = _get_point_on_circle_around_player()
