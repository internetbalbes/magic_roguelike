extends CharacterBody3D

@onready var body_tornado : GPUParticles3D = $GPUParticles3D
@onready var timer_remove_object : Timer = $timer_remove_object
@onready var timer_find_enemy_in_area : Timer = $timer_find_enemy_in_area
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D.shape
@onready var area3d_tornado_circle  = $area3d_tornado_circle
@onready var collision_tornado_circle  = $area3d_tornado_circle/CollisionShape3D
@export var player : CharacterBody3D

var player_tornado_speed = 20.0
var player_tornado_time_life : float = 5.0
var spell: SpellClass
var collider : Node3D
var collider_position : Vector3 = Vector3.ZERO
var enemies_in_tornado: Array
var min_distance_to_object = 0.0

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_tornado_speed = config.get_value("player_tornado", "player_tornado_speed", player_tornado_speed)
		timer_remove_object.wait_time = config.get_value("player_tornado", "player_tornado_shoot_time_life", 1.0)
		collision_tornado_circle.shape.radius = config.get_value("player_tornado", "player_tornado_radius", 5)		
		#config.save("res://settings.cfg")
	config = null
	if collider:
		if collider.get_groups().size() > 0:
			min_distance_to_object = collider._get_object_size() + collision_shape.radius
		else:
			min_distance_to_object = 1.0			

	if body_tornado.process_material is ShaderMaterial:
		body_tornado.process_material.set_shader_parameter("base_radius", collision_tornado_circle.shape.radius)
	body_tornado.emitting = false
	area3d_tornado_circle.monitoring = false
	timer_remove_object.start()
	
func _physics_process(delta: float) -> void:	
	if global_position.distance_to(collider_position) < min_distance_to_object:
		if is_instance_valid(collider) && collider.get_groups().size() > 0:
			body_tornado.global_position = collider.global_position
			if collider.get_groups()[0] == "enemy":
				body_tornado.global_transform.origin.y -= collider._get_object_height() / 2
		else:
			body_tornado.global_position = collider_position		
		mesh.visible = false
		set_physics_process(false)
		area3d_tornado_circle.monitoring = true
		timer_find_enemy_in_area.start()
		timer_remove_object.stop()
	else:		
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_position += direction * player_tornado_speed	* delta	

func _on_timer_remove_object_timeout() -> void:
	if abs(timer_remove_object.wait_time - body_tornado.lifetime) < 0.001:
		for obj in enemies_in_tornado:
			if is_instance_valid(obj):
				obj._set_position_freeze(Vector3.ZERO, false)
		call_deferred("queue_free")
	elif body_tornado.emitting:
		body_tornado.emitting = false
		timer_remove_object.wait_time = body_tornado.lifetime
		timer_remove_object.start()
	else:
		call_deferred("queue_free")
	
func _on_timer_find_enemy_in_area_timeout() -> void:
	enemies_in_tornado = area3d_tornado_circle.get_overlapping_bodies()	
	var count_enemies = enemies_in_tornado.size()
	if count_enemies > 0:
		var angle_shift = 330.0 / count_enemies
		var angle = 0
		for obj in enemies_in_tornado:
			var x = cos(deg_to_rad(angle))
			var z = sin(deg_to_rad(angle))		
			if is_instance_valid(obj):				
				obj._set_position_freeze(collider.global_position + Vector3(x, 0, z), true)
			angle += angle_shift	
	var time = player_tornado_time_life - body_tornado.lifetime
	if time < 0.001:
		timer_remove_object.wait_time = body_tornado.lifetime
	else:
		timer_remove_object.wait_time = time
	body_tornado.emitting = true
	timer_remove_object.wait_time = player_tornado_time_life
	timer_remove_object.start()

func set_collider(node: Node3D, pos: Vector3):
	collider = node
	collider_position = pos
