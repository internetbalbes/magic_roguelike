extends Node3D

@onready var timer_remove_object = $timer_remove_object
@onready var collision_thunderbolt_circle  = $area3d_thunderbolt_circle/CollisionShape3D
@onready var area3d_thunderbolt_circle  = $area3d_thunderbolt_circle
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@onready var lighting = $lighting
@export var player : CharacterBody3D

#thunderbolt's class name
var spell: SpellClass
#thunderbolt's collider
var collider : Node3D
#thunderbolt's collider position
var collider_position : Vector3 = Vector3.ZERO

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		timer_remove_object.wait_time = config.get_value("player_thunderbolt", "player_thunderbolt_time_life", 2)
		collision_thunderbolt_circle.shape.radius = config.get_value("player_thunderbolt", "player_thunderbol_radius", 2)
		#config.save("res://settings.cfg")
	config = null
	global_position = collider.global_position
	area3d_thunderbolt_circle.monitoring = true
	lighting.visible = false
	timer_find_enemy_in_area.start()
	
# collider's param node: target's node, target's position, max distance fly spell
func set_collider(node: Node3D, pos: Vector3, _max_distance: float):
	collider = node
	collider_position = pos	

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")

func rotate_towards_target(object, target_pos):
	var current = object.global_transform.basis.get_euler()
	var direction = (object.global_transform.origin - target_pos).normalized()
	var target_yaw = atan2(direction.x, direction.z)
	current.y = angle_difference(current.y, target_yaw)
	object.global_transform.basis = Basis().rotated(Vector3.UP, current.y)
	
func _on_timer_find_enemy_in_area_timeout() -> void:	
	if player:
		var list_lighting_on_enemy = []
		var enemies_in_area = area3d_thunderbolt_circle.get_overlapping_bodies()
		for obj in enemies_in_area:
			if obj == collider || obj.find_buf("wet"):
				obj.take_damage("thunderbolt", "", spell.damage)
				var obj_lighting = lighting.duplicate()
				#Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION
				player.world.add_child(obj_lighting)
				obj_lighting.global_position = obj.global_position + Vector3(0.0, - obj._get_object_height()/2 + obj_lighting.mesh.size.y/2, 0.0)
				rotate_towards_target(obj_lighting, player.global_position)
				obj_lighting.visible = true
				list_lighting_on_enemy.append(obj_lighting)
				
		if list_lighting_on_enemy.size() > 0:
			var timer = Timer.new()
			timer.wait_time = 0.1
			timer.autostart = true
			timer.timeout.connect(func():
				if timer.one_shot:
					for obj in list_lighting_on_enemy:
						if is_instance_valid(obj):
							obj.queue_free()
					list_lighting_on_enemy.clear()
					timer.queue_free()
				else:					
					timer.one_shot = true
					for obj in list_lighting_on_enemy:
						if is_instance_valid(obj):
							obj.mesh = null
							var obj_explosing = obj.get_child(0)
							(obj_explosing as GPUParticles3D).emitting = true
			)	
			player.world.add_child(timer)
	call_deferred("queue_free")
