extends Area3D

@onready var meshinstance : MeshInstance3D = $MeshInstance3D
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var timer_remove_object : Timer = $timer_remove_object
@export var player : CharacterBody3D

# damage skymage sphere for player
var skymage_sphere_damage = 1
# flag if player in the sphere
var player_in_area : bool = false
var magic_type = "guard"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		timer_remove_object.wait_time = config.get_value("enemy_skymage_sphere", "skymage_sphere_time_life", timer_remove_object.wait_time)
		collision.shape.radius = config.get_value("enemy_skymage_sphere", "skymage_sphere_radius", collision.shape.radius)
		skymage_sphere_damage = config.get_value("enemy_skymage_sphere", "skymage_sphere_damage", skymage_sphere_damage)	
		#config.save("res://settings.cfg")
	config = null
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	meshinstance.mesh.size = Vector2.ONE * 2 * collision.shape.radius
	if magic_type == "attack":
		global_position = Vector3(player.global_position.x, 0.05, player.global_position.z)
	else:
		meshinstance.visible = false

func _on_body_entered(_body: Node3D) -> void:
	player_in_area = true
	meshinstance.visible = true
	if timer_remove_object.is_stopped():
		timer_remove_object.start()

func _on_body_exited(_body: Node3D) -> void:
	player_in_area = false
	if magic_type == "guard":
		meshinstance.visible = false
		timer_remove_object.stop()

func _on_timer_remove_object_timeout() -> void:
	if player_in_area:
		player.take_damage(skymage_sphere_damage)
	if magic_type == "guard":
		timer_remove_object.start()
	else:
		monitoring = false
		call_deferred("queue_free")
