extends Node3D

@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_near_enemy  = $area3d_near_enemy/CollisionShape3D
@onready var area3d_near_enemy  = $area3d_near_enemy
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@onready var sprite_cutoff_air = $sprite_cutoff_air
@export var player : CharacterBody3D

var param_coldsteel = {}
var action_cold_steel_cutoff = false

func _ready()->void:
	collision_near_enemy.shape.radius = Globalsettings.player_coldsteel["detection_distance_near_enemy"]
	area3d_near_enemy.monitoring = false
	sprite_cutoff_air.visible = false
	
func action_cold_steel(node: Node3D, pos: Vector3, _param_coldsteel):
	param_coldsteel = _param_coldsteel
	sprite_cutoff_air.visible = true
	if node && (node.is_in_group("enemy") || node.is_in_group("portal")):
		if param_coldsteel.targets == 1 || node.is_in_group("portal"):
			var distance = global_position.distance_to(pos)
			if distance < collision_near_enemy.shape.radius:
				if node.is_in_group("enemy"):
					node.take_damage_beat("coldsteel", "", param_coldsteel.damage, pos)
				else:
					node.portal_free()
		else:
			area3d_near_enemy.monitoring = true
			timer_find_enemy_in_area.start()
	
func _check_near_enemy(pos):
	var distance = global_position.distance_to(pos)
	if distance < collision_near_enemy.shape.radius:			
		var direction_to_enemy = (pos - player.global_position).normalized()
		var forward = player.global_transform.basis.z.normalized() * -1.0  # Z przód w Godot
		var angle = rad_to_deg(forward.angle_to(direction_to_enemy))
		return angle <= Globalsettings.player_coldsteel["detection_angle_deg_near_enemy"]
	else:
		return false
			
func _on_timer_find_enemy_in_area_timeout() -> void:
	var enemies_in_area = area3d_near_enemy.get_overlapping_bodies()
	var i = 0
	for obj in enemies_in_area:
		if i < param_coldsteel.targets:
			i +=1
		else:
			break
		if _check_near_enemy(obj.global_position):
			obj.take_damage("coldsteel", "", param_coldsteel.damage)
	area3d_near_enemy.monitoring = false

func is_action_cold_steel_cutoff():
	return sprite_cutoff_air.visible

func action_cold_steel_cutoff_off(value):
	sprite_cutoff_air.visible = value
