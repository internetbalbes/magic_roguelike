extends CharacterBody3D

@onready var collision: CollisionShape3D = $CollisionShape3D
@export var world: Node3D
@export var player : CharacterBody3D

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

func _ready() -> void:
	if has_node("area_seeing"):
		area = get_node("area_seeing")
		collision_areaseeing = area.get_node("CollisionShape3D").shape
		collision_areaseeing.radius = Globalsettings.enemy_param[enemy_type]["enemy_area_scan_player"]
		area.body_entered.connect(_on_area_3d_body_entered)
		area.body_exited.connect(_on_area_3d_body_exited)	
	collision_shape = collision.shape
	label_health_value = Globalsettings.enemy_param[enemy_type]["label_health_max_value"]
	#_add_modificator_to_list("water_resist")
	#_add_buf_to_list("wet")
	if randi_range(1, 100) <  Globalsettings.enemy_param["common"]["probability_modificator"]:
		var keys = Globalsettings.enemy_list_modificators.keys()
		_add_modificator_to_list(keys[randi_range(0, keys.size()-1)])

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()

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
				if randi_range(1, 100) <  Globalsettings.enemy_param[enemy_type]["probability_card"]:
					player.add_card()
				if area:
					area.monitoring = false
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)
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
		
