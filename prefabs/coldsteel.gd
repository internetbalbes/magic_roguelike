extends Node3D

@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_near_enemy  = $area3d_near_enemy/CollisionShape3D
@onready var area3d_near_enemy  = $area3d_near_enemy
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
@export var player : CharacterBody3D

# sektor wykrywania (np. 60 stopni)
var detection_angle_deg_near_enemy = 40.0
var single_steel_damage = 1
var splash_steel_damage = 1

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		detection_angle_deg_near_enemy =  config.get_value("player_coldsteel", "detection_angle_deg_near_enemy", detection_angle_deg_near_enemy)
		collision_near_enemy.shape.radius = config.get_value("player_coldsteel", "detection_distance_near_enemy", 1.5)
		single_steel_damage = config.get_value("player_coldsteel", "single_steel_damage", single_steel_damage)
		splash_steel_damage = config.get_value("player_coldsteel", "splash_steel_damage", splash_steel_damage)
		#config.save("res://settings.cfg")
	config = null
	area3d_near_enemy.monitoring = false
	
func action_cold_steel(node: Node3D, pos: Vector3, type: String):
	if node && (node.is_in_group("enemy") || node.is_in_group("portal")):
		if type == "single":
			var distance = global_position.distance_to(pos)
			if distance < collision_near_enemy.shape.radius:
				if node.is_in_group("enemy"):
					node.take_damage("coldsteel", "", single_steel_damage)
				else:
					node.portal_free()
		elif type == "splash":
			area3d_near_enemy.monitoring = true
			timer_find_enemy_in_area.start()
	
func _check_near_enemy(pos):	
	var direction_to_enemy = (pos - global_position).normalized()
	var forward = global_transform.basis.z.normalized() * -1.0  # Z przód w Godot
	var angle = rad_to_deg(acos(forward.dot(direction_to_enemy)))
	return angle <= detection_angle_deg_near_enemy / 2			
			
func _on_timer_find_enemy_in_area_timeout() -> void:
	var enemies_in_area = area3d_near_enemy.get_overlapping_bodies()	
	for obj in enemies_in_area:
		if _check_near_enemy(obj.global_position):
			obj.take_damage("coldsteel", "", splash_steel_damage)
	area3d_near_enemy.emitting = false
