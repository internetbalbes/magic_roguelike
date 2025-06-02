extends Area3D

@onready var meshinstance : MeshInstance3D = $MeshInstance3D
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var timer_remove_object : Timer = $timer_remove_object
@onready var explosing : GPUParticles3D = $explosing
@export var player : CharacterBody3D

# flag if player in the sphere
var player_in_area : bool = false
var magic_type = "guard"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision.shape.radius = Globalsettings.enemy_skymage_sphere["skymage_sphere_radius"]
	explosing.emitting = false
	explosing.one_shot = true
	meshinstance.mesh.size = Vector2.ONE * 2 * collision.shape.radius
	timer_remove_object.wait_time = Globalsettings.enemy_skymage_sphere["skymage_sphere_time_life"]
	connect("body_exited", _on_body_exited)
	if magic_type == "attack":
		global_position = Vector3(player.global_position.x, 0.05, player.global_position.z)
		timer_remove_object.start()
		player_in_area = true
	else:
		meshinstance.visible = false
		connect("body_entered", _on_body_entered)

func _on_body_entered(_body: Node3D) -> void:
	player_in_area = true	
	if timer_remove_object.is_stopped():
		meshinstance.visible = true
		timer_remove_object.wait_time =Globalsettings.enemy_skymage_sphere["skymage_sphere_time_life"]
		timer_remove_object.start()

func _on_body_exited(_body: Node3D) -> void:
	player_in_area = false
	
func _on_timer_remove_object_timeout() -> void:	
	if magic_type == "guard":
		if meshinstance.visible:
			if player_in_area:
				player.take_damage(Globalsettings.enemy_skymage_sphere["skymage_sphere_damage"])
			meshinstance.visible = false
			timer_remove_object.wait_time = Globalsettings.enemy_skymage_sphere["skymage_sphere_reload_time"]
			timer_remove_object.start()
			explosing.restart()
		elif player_in_area:
			_on_body_entered(player)
	else:
		if player_in_area:
			player.take_damage(Globalsettings.enemy_skymage_sphere["skymage_sphere_damage"])
		monitoring = false
		meshinstance.visible = false
		explosing.restart()
		await get_tree().create_timer(explosing.lifetime).timeout
		call_deferred("queue_free")
	
