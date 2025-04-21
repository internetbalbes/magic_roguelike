extends CharacterBody3D

@onready var raycast = $Camera3D/RayCast3D
@onready var label_health = $CanvasLayer/label_health
@onready var image_pointcatch = $CanvasLayer/image_pointcatch
@onready var progressbar_world_slowing = $CanvasLayer/progressbar_world_slowing
@onready var timer_reload_spell = $timer_reload_spell
@onready var texturerect_vignette = $CanvasLayer/texturerect_vignette
@onready var progressbar_reload_spell = $CanvasLayer/progressbar_reload_spell
@onready var label_spell = $CanvasLayer/label_spell
@export var prefathunderbolt : PackedScene
@export var prefabwaterball : PackedScene
@export var prefabtornado : PackedScene
@export var world: Node3D

# List spell
var spells : Array
# player's initial state
var state = playerstate.IDLE
# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING	# state jumping	
}
var player_max_health: int = 5
# player's speed normal
var player_speed_walk = 3
# player's speed jump
var player_jump_velocity = 3
# camer's sensitivity
var player_rotate_sensitivity = 0.085
var current_health: int = player_max_health
var world_scale_slowing = 2
# common time slowing world
var world_common_time_slowing = 60
# time reload spell
var time_reload_spell = 1
# speed scroll_container spells
var spell_currently_index = 1
# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_speed_walk = config.get_value("player", "player_speed_walk", player_speed_walk)
		player_max_health = config.get_value("player", "player_max_health", player_max_health)
		player_jump_velocity = config.get_value("player", "player_jump_velocity", player_jump_velocity)
		player_rotate_sensitivity = config.get_value("player", "player_rotate_sensitivity", player_rotate_sensitivity)
		world_scale_slowing = config.get_value("player", "world_scale_slowing", world_scale_slowing)
		progressbar_world_slowing.max_value = config.get_value("player", "world_common_time_slowing", 60)
		time_reload_spell = config.get_value("player", "time_reload_spell", 1)
		# spell waterball
		var mana_cost = config.get_value("player", "waterball_spell_mana_cost", 1)
		var damage = config.get_value("player", "waterball_spell_damage", 1)
		var type = config.get_value("player", "waterball_spell_type", "sphere")
		var spell = SpellClass.new("waterball", mana_cost, damage, type)
		spells.append(spell)
		# spell thunderbolt
		mana_cost = config.get_value("player", "thunderbolt_spell_mana_cost", 1)
		damage = config.get_value("player", "thunderbolt_spell_damage", 1)
		type = config.get_value("player", "thunderbolt_spell_type", "single")
		spell = SpellClass.new("thunderbolt", mana_cost, damage, type)
		spells.append(spell)
		# spell tornado
		mana_cost = config.get_value("player", "tornado_spell_mana_cost", 1)
		damage = config.get_value("player", "tornado_spell_damage", 1)
		type = config.get_value("player", "tornado_spell_type", "sphere")
		spell = SpellClass.new("tornado", mana_cost, damage, type)
		spells.append(spell)			
		#config.save("res://settings.cfg")
	config = null
	Engine.time_scale = 1.0
	current_health = player_max_health
	label_spell.text = spells[spell_currently_index].spell_name.to_upper()
	progressbar_reload_spell.step = 0.1
	progressbar_reload_spell.value = 1
	progressbar_reload_spell.max_value = 1
	texturerect_vignette.visible = false
	progressbar_world_slowing.value = progressbar_world_slowing.max_value	
	_on_health_changed(player_max_health)
	connect("health_changed", _on_health_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
		spell_currently_index -=1
		if spell_currently_index < 0:
			spell_currently_index = spells.size() - 1
		label_spell.text = spells[spell_currently_index].spell_name.to_upper()
	elif event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
		spell_currently_index +=1
		if spell_currently_index == spells.size():
			spell_currently_index = 0
		label_spell.text = spells[spell_currently_index].spell_name.to_upper()
	if event is InputEventMouseButton:		
		if  event.button_index == MOUSE_BUTTON_LEFT && event.pressed && timer_reload_spell.is_stopped():
			if spells[spell_currently_index].spell_name.to_lower() == "thunderbolt":
				create_spell(prefathunderbolt.instantiate())				
			elif spells[spell_currently_index].spell_name.to_lower() == "waterball":
				create_spell(prefabwaterball.instantiate())				
			elif spells[spell_currently_index].spell_name.to_lower() == "tornado":
				create_spell(prefabtornado.instantiate())				
		elif event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			if Engine.time_scale < 1:
				Engine.time_scale = 1.0
				texturerect_vignette.visible = false
			elif progressbar_world_slowing.value > 0:
				Engine.time_scale /= world_scale_slowing
				texturerect_vignette.visible = true	
	elif event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * player_rotate_sensitivity))

func _physics_process(delta: float) -> void:
	# find collide with object
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider && collider.get_groups().size() > 0 && collider.get_groups()[0] in ["portal", "enemy"]:
			image_pointcatch.modulate = Color(1, 0, 0)  # RGB (czerwony)
		else:
			image_pointcatch.modulate = Color(1, 1, 1)  # RGB (white)
	else:
		image_pointcatch.modulate = Color(1, 1, 1)  # RGB (white)			
	if Engine.time_scale < 1.0:
		progressbar_world_slowing.value -= delta / Engine.time_scale
		if progressbar_world_slowing.value < 0.001:
			Engine.time_scale = 1.0
			texturerect_vignette.visible = false
	if !is_on_floor():
		# Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
		state = playerstate.JUMPING
	else:
		if Input.is_action_pressed("jump"):
			velocity.y = player_jump_velocity
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * player_speed_walk
			velocity.z = direction.z * player_speed_walk
			state = playerstate.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, player_speed_walk)
			velocity.z = move_toward(velocity.z, 0, player_speed_walk)
			state = playerstate.IDLE
	move_and_slide()

func create_spell(prefab: Node3D):
	prefab.spell = spells[spell_currently_index]
	prefab.player = self	
	prefab.set_collider(raycast.get_collider(), raycast.get_collision_point())
	world.add_child(prefab)
	prefab.global_transform.origin = raycast.global_transform.origin
	prefab.global_transform.basis = raycast.global_transform.basis
	timer_reload_spell.start()
	progressbar_reload_spell.value = 0
	
func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, player_max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)
	if !is_alive():
		get_tree().call_deferred("reload_current_scene")

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, player_max_health)
	emit_signal("health_changed", current_health)

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func _on_timer_reload_spell_timeout() -> void:
	progressbar_reload_spell.value += timer_reload_spell.wait_time
	if progressbar_reload_spell.value > 0.99:
		timer_reload_spell.stop()
