extends CharacterBody3D

@onready var body_waterball : GPUParticles3D = $GPUParticles3D
@onready var timer_remove_object : Timer = $timer_remove_object
@onready var collision_shape = $CollisionShape3D.shape
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_waterball_circle  = $area3d_waterball_circle/CollisionShape3D
@onready var area3d_waterball_circle  = $area3d_waterball_circle
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@export var player : CharacterBody3D

var player_waterball_speed = 20.0
var spell: SpellClass
var collider : Node3D
var collider_position : Vector3 = Vector3.ZERO
var min_distance_to_object = 0

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_waterball_speed = config.get_value("player_waterball", "player_waterball_speed", player_waterball_speed)
		timer_remove_object.wait_time = config.get_value("player_waterball", "player_waterball_time_life", 2)
		collision_waterball_circle.shape.radius = config.get_value("player_waterball", "player_waterball_radius", 2)
		#config.save("res://settings.cfg")
	config = null
	if collider && collider.get_groups().size() > 0:
		if collider.get_groups()[0] == "portal" || collider.get_groups()[0] == "enemy":
			min_distance_to_object = collider._get_object_size() + collision_shape.radius
	body_waterball.emitting = false
	area3d_waterball_circle.monitoring = false
	timer_remove_object.start()
	
func _physics_process(delta: float) -> void:
	if min_distance_to_object > 0 && global_position.distance_to(collider_position) < min_distance_to_object:
		mesh.visible = false
		set_physics_process(false)
		area3d_waterball_circle.monitoring = true
		timer_find_enemy_in_area.start()
		timer_remove_object.stop()
	else:		
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_position += direction * player_waterball_speed * delta

func set_collider(node: Node3D, pos: Vector3):
	collider = node
	collider_position = pos
	
func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")

func _on_timer_find_enemy_in_area_timeout() -> void:
	var enemies_in_waterball = area3d_waterball_circle.get_overlapping_bodies()	
	if enemies_in_waterball.size() > 0:
		for obj in enemies_in_waterball:
			if obj.get_groups().size() > 0:
				if obj.get_groups()[0] == "portal":
					for obj_enemy in obj.list_enemy:
						obj_enemy._set_target(player)
					obj.portal_free()
				elif obj.get_groups()[0] == "enemy":
					obj.take_damage("wet", spell.damage)
	area3d_waterball_circle.monitoring = true
	body_waterball.emitting = true	
	timer_remove_object.wait_time = body_waterball.lifetime
	timer_remove_object.start()
