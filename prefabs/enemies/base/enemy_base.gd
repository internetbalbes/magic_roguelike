extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var area: Area3D = $area_seeing
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var label_health: ProgressBar = $subviewport/progressbar_health
@onready var label_buf: HBoxContainer = $subviewport/hboxcontainer_status
@export var world: Node3D
@export var player : CharacterBody3D

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
var list_modificators: Array = ["water_resist"]
# modificators value's probability
var probability_modificator = 50.0
# array of enemy modificators
var enemy_list_modificators: Array
# cards value's probability
var probability_card = 50.0
# object portal spawn
var portal: Node3D
# enemy time's stand still
var time_stand_still = 0

func _ready() -> void:
	collision_areaseeing = area.get_node("CollisionShape3D").shape
	collision_shape = collision.shape
	area.body_entered.connect(_on_area_3d_body_entered)
	area.body_exited.connect(_on_area_3d_body_exited)
	label_health.value = label_health.max_value
	for modificator in list_modificators:
		if randi_range(1, 100) < probability_modificator:
			_add_modificator_to_list(modificator)

func _physics_process(delta: float) -> void:
	if  !is_on_floor():
		## Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta		
		move_and_slide()
	
func _on_area_3d_body_entered(_body: Node3D) -> void:
	player_in_area = true
		
func _on_area_3d_body_exited(_body: Node3D) -> void:
	player_in_area = false

func take_damage(spell, buf, amount: int):
	if is_alive():
		var is_demage = true
		match spell:
			"waterball": is_demage = !enemy_list_modificators.has("water_resist")
		if is_demage:
			label_health.value -= amount
			if !is_alive():
				collision.set_deferred("disabled", true)
				if randi_range(1, 100) < probability_card:
					player.add_card()
				area.monitoring = false
				if portal:
					portal.list_enemy.erase(self)
					portal.list_new_enemy.erase(self)
				$sprite_status.set_deferred("visible", false)
			elif buf:
				_add_buf_to_list(buf)

func _set_portal(object: Node3D, angle: float) ->void:
	portal = object
	if portal:
		var x = 2 * cos(deg_to_rad(angle))
		var z = 2 * sin(deg_to_rad(angle))	
		global_transform.origin = portal.global_transform.origin + Vector3(x, collision_shape.height, z)

func is_alive() -> bool:
	return label_health.value > 0

func rotate_towards_target(target_pos, delta):
	var current = global_transform.basis.get_euler()
	var direction = (global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = lerp_angle(current.y, target_yaw, delta * 5.0)
	global_transform.basis = Basis().rotated(Vector3.UP, current.y)
	
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
	if !enemy_list_modificators.has(name_modificator):
		var icon = TextureRect.new()		
		if name_modificator == "water_resist":  
			icon.texture = load("res://sprites/water_resist_icon.png") as Texture2D
		icon.stretch_mode = TextureRect.STRETCH_KEEP	
		label_buf.add_child(icon)
		enemy_list_modificators.append(name_modificator)
		
func find_buf(name_buf)->bool:
	return list_buf.has(name_buf)

func _on_area_seeing_body_entered(_body: Node3D) -> void:
	player_in_area = true


func _on_area_seeing_body_exited(_body: Node3D) -> void:
	player_in_area = true
