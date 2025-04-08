extends Area3D

const SPEED = 3.0

@onready var fireball_mesh : MeshInstance3D = $MeshInstance3D
@export var player : CharacterBody3D

# life fireball's time
var time = 0

func _physics_process(delta: float) -> void:
	var shader = (fireball_mesh.get_surface_override_material(0) as ShaderMaterial)
	shader.set_shader_parameter("time", Time.get_ticks_msec() / 1000)
	var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
	global_transform.origin += direction
	time += delta
	if time > 1:
		queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.take_damage(1)  # Zadaj 5 obrażeń graczowi	
	queue_free()		
