extends Area3D

@onready var mesh : SphereMesh = $MeshInstance3D.mesh
@onready var material = mesh.material as ShaderMaterial
@onready var collision : CollisionShape3D = $CollisionShape3D
@export var player : CharacterBody3D

# skymage sphere's time life
var skymage_sphere_time_life = 1.0
# skymage sphere's radius
var skymage_sphere_radius = 1.0
# damage skymage sphere for player
var skymage_sphere_damage = 1
# flag if player in the sphere
var player_in_area : bool = false
# shader's animation
var time = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision.shape.radius = skymage_sphere_radius
	global_position = player.global_position
	mesh.radius = collision.shape.radius
	mesh.height = 2 * skymage_sphere_radius

func _process(delta):
	time += delta
	material.set_shader_parameter("time", time)
	if time > skymage_sphere_time_life:
		if player_in_area:
			player.take_damage(skymage_sphere_damage)
		monitoring = false
		call_deferred("queue_free")
	
func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_area = true

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player_in_area = false

func _set_param(time_life, radius, demage):
	skymage_sphere_time_life = time_life
	skymage_sphere_radius = radius
	skymage_sphere_damage = demage
		
