extends CharacterBody3D

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var label_health: ProgressBar = $subviewport/progressbar_health
@onready var label_buf: HBoxContainer = $subviewport/hboxcontainer_status
@onready var sprite_status: Sprite3D = $sprite_status
@onready var blood_spot: Decal = $blood_spot
@onready var blood_drop: GPUParticles3D = $blood_drop
@export var world: Node3D
@export var player : CharacterBody3D

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
# array of all modificators
var list_modificators = {
	"water_resist": {"texture": load("res://sprites/water_resist_icon.png")},
	"magic_resist": {"texture": load("res://sprites/magic_resist_icon.png")}
}
# modificators value's probability
var probability_modificator = 50.0
# array of enemy modificators
var enemy_list_modificators: Array
# cards value's probability
var probability_card = 50.0
# object portal spawn
var portal: Node3D
var size_blood_on_floor : Vector3 = Vector3.ONE
var enemy_config = ""
var enemy_type = "boss"

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:		
		size_blood_on_floor.x = config.get_value(enemy_config, "size_blood_on_floor_x", size_blood_on_floor.x)
		size_blood_on_floor.y = config.get_value(enemy_config, "size_blood_on_floor_y", size_blood_on_floor.y)
		size_blood_on_floor.z = config.get_value(enemy_config, "size_blood_on_floor_z", size_blood_on_floor.z)
	if has_node("area_seeing"):
		area = get_node("area_seeing")
		collision_areaseeing = area.get_node("CollisionShape3D").shape
		area.body_entered.connect(_on_area_3d_body_entered)
		area.body_exited.connect(_on_area_3d_body_exited)
	collision_shape = collision.shape
	label_health.value = label_health.max_value
	if randi_range(1, 100) < probability_modificator:
		var keys = list_modificators.keys()
		_add_modificator_to_list(keys[randi_range(0, keys.size()-1)])
	blood_drop.emitting = false
	blood_drop.one_shot = true

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	
func _on_area_3d_body_entered(_body: Node3D) -> void:
	player_in_area = true
		
func _on_area_3d_body_exited(_body: Node3D) -> void:
	player_in_area = false

func take_damage_beat(spell, buf, amount, _position):
	blood_drop.position = to_local(_position)
	blood_drop.restart()
	take_damage(spell, buf, amount)
	blood_spot.modulate.a = 1.0
	blood_spot.visible = true
	var tween_blood = blood_spot.create_tween()
	tween_blood.tween_property(blood_spot, "modulate:a", 0.0, 5.0).set_trans(Tween.TRANS_LINEAR)
	tween_blood.tween_callback(func():
		blood_spot.visible = false
	)
	spawn_blood_on_floor()
		
func take_damage(spell, buf, amount: int):
	if is_alive():
		var is_demage = true
		if enemy_list_modificators.size() > 0 || spell != "coldsteal":
			if !enemy_list_modificators.has("magic_resist"):
				match spell:
					"waterball": is_demage = !enemy_list_modificators.has("water_resist")
			else:
				is_demage = false
		if is_demage:
			label_health.value -= amount
			if !is_alive():
				collision.set_deferred("disabled", true)
				if randi_range(1, 100) < probability_card:
					player.add_card()
				if area:
					area.monitoring = false
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)
				$sprite_status.set_deferred("visible", false)
			elif buf:
				_add_buf_to_list(buf)

func _set_portal(object: Node3D, _angle: float) ->void:
	portal = object
	if portal:
		global_transform.origin = portal.global_transform.origin + Vector3(0, collision_shape.height/2, 0)

func is_alive() -> bool:
	return label_health.value > 0

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
		var icon = TextureRect.new()
		if name_buf == "wet":  
			icon.texture = load("res://sprites/wet_icon.png") as Texture2D
		icon.stretch_mode = TextureRect.STRETCH_KEEP	
		label_buf.add_child(icon)
		list_buf.append(name_buf)	
	
func _add_modificator_to_list(name_modificator):
	var icon = TextureRect.new()
	icon.texture = list_modificators[name_modificator].texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP	
	label_buf.add_child(icon)
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
	var decal = blood_spot.duplicate()		
	# Ustaw rozmiar decal'a
	decal.size = size_blood_on_floor
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
		
