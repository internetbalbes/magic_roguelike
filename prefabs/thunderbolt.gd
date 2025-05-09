extends CharacterBody3D

@onready var collision_shape = $CollisionShape3D.shape
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var timer_remove_object = $timer_remove_object
@onready var collision_thunderbolt_circle  = $area3d_thunderbolt_circle/CollisionShape3D
@onready var area3d_thunderbolt_circle  = $area3d_thunderbolt_circle
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@onready var lighting = $lighting
@export var player : CharacterBody3D

#thunderbolt's speed
var player_thunderbolt_speed = 20.0
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


func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_thunderbolt_speed = config.get_value("player_thunderbolt", "player_thunderbolt_speed", player_thunderbolt_speed)
		timer_remove_object.wait_time = config.get_value("player_thunderbolt", "player_thunderbolt_time_life", 2)
		collision_thunderbolt_circle.shape.radius = config.get_value("player_thunderbolt", "player_thunderbol_radius", 2)
		#config.save("res://settings.cfg")
	config = null
	if collider && collider.get_groups().size() > 0:
		if collider.get_groups()[0] == "portal" || collider.get_groups()[0] == "enemy":
			min_distance_to_object = collider._get_object_size() + collision_shape.radius
	area3d_thunderbolt_circle.monitoring = false
	lighting.visible = false
	timer_remove_object.start()
	
func _physics_process(delta: float) -> void:
	if min_distance_to_object > 0 && global_position.distance_to(collider_position) < min_distance_to_object:		
		if is_instance_valid(collider) && collider.is_in_group("enemy"):
			mesh.visible = false
			set_physics_process(false)
			area3d_thunderbolt_circle.monitoring = true
			timer_find_enemy_in_area.start()
			timer_remove_object.stop()			
		else:
			call_deferred("queue_free")		
	else:		
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_position += direction * player_thunderbolt_speed *  delta
		if global_position.distance_to(player.global_position) > max_distance_to_demage:
			call_deferred("queue_free")

# collider's param node: target's node, target's position, max distance fly spell
func set_collider(node: Node3D, pos: Vector3, max_distance: float):
	collider = node
	collider_position = pos
	max_distance_to_demage = max_distance	

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")

func _on_timer_find_enemy_in_area_timeout() -> void:
	if player:
		var list_lighting_on_enemy = []
		var enemies_in_area = area3d_thunderbolt_circle.get_overlapping_bodies()
		for obj in enemies_in_area:
			if obj == collider || obj.find_buf("wet"):
				obj.take_damage("thunderbolt", "", spell.damage)
				var obj_lighting = lighting.duplicate()
				player.world.add_child(obj_lighting)
				obj_lighting.global_position = obj.global_position + Vector3(0, (obj._get_object_height() + obj_lighting.mesh.size.y)/2, 0)
				obj_lighting.visible = true
				list_lighting_on_enemy.append(obj_lighting)
		if list_lighting_on_enemy.size() > 0:
			var timer = Timer.new()
			timer.wait_time = 1.0
			timer.one_shot = true
			timer.autostart = true
			timer.timeout.connect(func():
				for obj in list_lighting_on_enemy:
					if is_instance_valid(obj):
						obj.queue_free()
				list_lighting_on_enemy.clear()
				timer.queue_free()
			)	
			player.world.add_child(timer)
	call_deferred("queue_free")
