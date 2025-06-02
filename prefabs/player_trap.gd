extends Area3D

@onready var body_explosing : GPUParticles3D = $GPUParticles3D
@onready var timer_remove_object : Timer = $timer_remove_object
@onready var collision_shape = $CollisionShape3D.shape
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var collision_trap_circle  = $area3d_trap_circle/CollisionShape3D
@onready var area3d_trap_circle  = $area3d_trap_circle
@onready var timer_find_enemy_in_area = $timer_find_enemy_in_area
#thunderbolt's class name
var spell: SpellClass

func _ready()->void:
	collision_trap_circle.shape.radius = Globalsettings.player_trap["player_trap_radius"]
	body_explosing.emitting = false
	area3d_trap_circle.monitoring = false
	
func _on_body_entered(_body: Node3D) -> void:
	mesh.visible = false
	area3d_trap_circle.monitoring = true
	timer_find_enemy_in_area.start()	
	
func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")

func _on_timer_find_enemy_in_area_timeout() -> void:
	var enemies_in_trap = area3d_trap_circle.get_overlapping_bodies()	
	for obj in enemies_in_trap:
		obj.take_damage("trap", "", spell.damage)
	area3d_trap_circle.monitoring = false
	body_explosing.emitting = true	
	timer_remove_object.wait_time = body_explosing.lifetime
	timer_remove_object.start()
