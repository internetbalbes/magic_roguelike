extends Node3D

@onready var timer_remove_object = $timer_remove_object
@onready var collision_freeze_circle  = $area3d_freeze_circle/CollisionShape3D
@onready var area3d_freeze_circle  = $area3d_freeze_circle
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@export var player : CharacterBody3D

#freeze's class name
var spell: SpellClass
#freeze's collider
var collider : Node3D
#freeze's collider position
var collider_position : Vector3 = Vector3.ZERO

func _ready()->void:
	timer_remove_object.wait_time = Globalsettings.player_freeze["player_freeze_time_effect"]
	collision_freeze_circle.shape.radius = Globalsettings.player_freeze["player_freeze_radius"]
	global_position = collider.global_position
	area3d_freeze_circle.monitoring = true
	timer_find_enemy_in_area.start()

func _set_global_transform(_value):
	pass

# collider's param node: target's node, target's position, max distance fly spell
func set_collider(node: Node3D, pos: Vector3, _max_distance: float):
	collider = node
	collider_position = pos	

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")
	
func _on_timer_find_enemy_in_area_timeout() -> void:	
	if player:
		var enemies_in_area = area3d_freeze_circle.get_overlapping_bodies()
		for obj in enemies_in_area:
			if (obj == collider || obj.find_buf("wet")) && obj.object_is_freezed():
				obj._set_freezing(Globalsettings.player_freeze["player_freeze_time_life"])
		timer_remove_object.start()
