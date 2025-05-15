extends CharacterBody3D

@onready var body_tornado : MeshInstance3D = $MeshInstance3D2
@onready var timer_remove_object : Timer = $timer_remove_object
@onready var timer_find_enemy_in_area : Timer = $timer_find_enemy_in_area
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D.shape
@onready var area3d_tornado_circle  = $area3d_tornado_circle
@onready var collision_tornado_circle  = $area3d_tornado_circle/CollisionShape3D
@export var player : CharacterBody3D

var player_tornado_speed = 20.0
var player_tornado_time_life : float = 5.0
#thunderbolt's class name
var spell: SpellClass
#thunderbolt's collider
var collider : Node3D
#thunderbolt's collider position
var collider_position : Vector3 = Vector3.ZERO
#min distance to collider
var min_distance_to_object = 0
#min distance to collider
var max_distance_to_demage = 0
var enemies_in_tornado: Array

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_tornado_speed = config.get_value("player_tornado", "player_tornado_speed", player_tornado_speed)
		timer_remove_object.wait_time = config.get_value("player_tornado", "player_tornado_shoot_time_life", 1.0)
		collision_tornado_circle.shape.radius = config.get_value("player_tornado", "player_tornado_radius", 5)		
		#config.save("res://settings.cfg")
	config = null
	if collider:
		if collider.is_in_group("enemy"):
			min_distance_to_object = collider._get_object_size() + collision_shape.radius
		else:
			min_distance_to_object = 1.0
	(body_tornado.mesh as CylinderMesh).top_radius = collision_tornado_circle.shape.radius
	(body_tornado.mesh as CylinderMesh).bottom_radius = collision_tornado_circle.shape.radius
	body_tornado.visible = false
	area3d_tornado_circle.monitoring = false
	timer_remove_object.start()
	
func _physics_process(delta: float) -> void:	
	if global_position.distance_to(collider_position) < min_distance_to_object:
		rotation = Vector3.ZERO
		body_tornado.global_position += Vector3(0, (body_tornado.mesh as CylinderMesh).height/4, 0)	
		mesh.visible = false
		set_physics_process(false)
		area3d_tornado_circle.monitoring = true
		timer_find_enemy_in_area.start()
		timer_remove_object.stop()
	else:		
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_position += direction * player_tornado_speed	* delta
		if global_position.distance_to(player.global_position) > max_distance_to_demage:
			call_deferred("queue_free")

func _set_global_transform(value):
	global_transform.origin = value.origin
	global_transform.basis = value.basis

# collider's param node: target's node, target's position, max distance fly spell
func set_collider(node: Node3D, pos: Vector3, max_distance: float):
	collider = node
	collider_position = pos
	max_distance_to_demage = max_distance

func _on_timer_remove_object_timeout() -> void:
	for obj in enemies_in_tornado:
		if is_instance_valid(obj):
			obj._set_position_freeze(Vector3.ZERO, false)
	call_deferred("queue_free")	
	
func _on_timer_find_enemy_in_area_timeout() -> void:
	enemies_in_tornado = area3d_tornado_circle.get_overlapping_bodies()	
	var count_enemies = enemies_in_tornado.size()
	if count_enemies > 0:
		var angle_shift = 330.0 / count_enemies
		var angle = 0
		var _collider_position = Vector3(collider_position.x, 0.0, collider_position.z)
		for obj in enemies_in_tornado:
			var x = cos(deg_to_rad(angle))
			var z = sin(deg_to_rad(angle))
			if is_instance_valid(obj):
				obj._set_position_freeze(_collider_position + Vector3(x, 0, z), true)
			angle += angle_shift	
	body_tornado.visible = true
	timer_remove_object.wait_time = player_tornado_time_life
	timer_remove_object.start()
