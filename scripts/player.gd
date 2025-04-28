extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var image_pointcatch = $interface/aim
@onready var timer_reload_spell = $timer_reload_spell
@onready var timer_portal_reload : Timer = $timer_portal_reload

@onready var label_health = $interface/hp/hp
@onready var progressbar_reload_spell = $interface/spells/book/progressbar_reload_spell
@onready var progressbar_mana = $interface/mana/progressbar_mana
@onready var label_mana = $interface/mana/progressbar_mana/labelmana
@onready var texturerect_base = $interface/spells/book
@onready var texturerect_overlay = $interface/spells/book/spell_icon
@onready var label_portal_reload = $interface/portal_spawn_time_left/portal_icon/portal_spawn_time_left
@onready var label_mana_cost = $interface/spells/mana_cost
@onready var parent_hboxcontainer_card = $interface/Control
@onready var hboxcontainer_card = $interface/Control/hboxcontainer_card
@onready var texturerect_card: TextureRect = $interface/texturerect_card

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
# time reload spell
var time_reload_spell = 1.0
# speed scroll_container spells
var spell_currently_index = 1
# time reload portal
var time_reload_portal = 10.0
# currently time reload portal
var time_currently_reload_portal = time_reload_portal
#list file spels
var spell_thunderbolt = preload("res://sprites/thunderbolt.png") 
var spell_waterball = preload("res://sprites/waterball_icon.png")
var spell_tornado = preload("res://sprites/tornado_icon.png")
var texturerect_card_set = Vector2.ZERO
#list file cards
var card_all_list_enemy: Array = ["card_mana_potion", "card_hp_potion", "card_mana_max_increase", "card_mana_max"]
var card_mana_potion = preload("res://sprites/card_mana_potion.png") 
var card_hp_potion = preload("res://sprites/card_hp_potion.png")
var card_mana_max_increase = preload("res://sprites/card_mana_max_increase.png")
var card_mana_max = preload("res://sprites/card_mana_max.png")
var card_scale = 2
var card_size = card_scale * Vector2(32, 48)
var card_currently_index = -1
var card_list : Array
var card_list_animation : Array
var card_mana_potion_mana_increase = 2
var card_hp_potion_hp_increase = 2

# Sygnalizacja zmiany zdrowia
signal health_changed(new_health)

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_speed_walk = config.get_value("player", "player_speed_walk", player_speed_walk)
		player_max_health = config.get_value("player", "player_max_health", player_max_health)
		player_jump_velocity = config.get_value("player", "player_jump_velocity", player_jump_velocity)
		player_rotate_sensitivity = config.get_value("player", "player_rotate_sensitivity", player_rotate_sensitivity)
		time_reload_spell = config.get_value("player", "time_reload_spell", time_reload_spell)
		time_reload_portal = config.get_value("player", "time_reload_portal", time_reload_portal)
		progressbar_mana.max_value =  config.get_value("player", "player_max_mana", 10)
		# spell waterball
		var mana_cost = config.get_value("spells", "waterball_spell_mana_cost", 1)
		var damage = config.get_value("spells", "waterball_spell_damage", 1)
		var type = config.get_value("spells", "waterball_spell_type", "sphere")
		var spell = SpellClass.new("waterball", mana_cost, damage, type)
		spells.append(spell)
		# spell thunderbolt
		mana_cost = config.get_value("spells", "thunderbolt_spell_mana_cost", 1)
		damage = config.get_value("spells", "thunderbolt_spell_damage", 1)
		type = config.get_value("spells", "thunderbolt_spell_type", "single")
		spell = SpellClass.new("thunderbolt", mana_cost, damage, type)
		spells.append(spell)
		# spell tornado
		mana_cost = config.get_value("spells", "tornado_spell_mana_cost", 1)
		damage = config.get_value("spells", "tornado_spell_damage", 1)
		type = config.get_value("spells", "tornado_spell_type", "sphere")
		spell = SpellClass.new("tornado", mana_cost, damage, type)
		spells.append(spell)
		#cards
		card_mana_potion_mana_increase  = config.get_value("cards", "card_mana_potion_mana_increase", card_mana_potion_mana_increase)
		card_hp_potion_hp_increase  = config.get_value("cards", "card_hp_potion_hp_increase", card_hp_potion_hp_increase)
		#config.save("res://settings.cfg")
	config = null
	texturerect_card.visible = false
	texturerect_card.size = Vector2(card_size.x, card_size.y)
	var rect = Vector2(8 * card_size.x, card_size.y)
	parent_hboxcontainer_card.set_deferred("size", rect) 
	var top = camera.get_viewport().get_visible_rect().size.y - rect.y
	var left = (camera.get_viewport().get_visible_rect().size.x - rect.x) / 2.0	
	parent_hboxcontainer_card.position = Vector2(left, top)	
	for card in hboxcontainer_card.get_children():
		card.custom_minimum_size = card_size
		card.expand = true
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	texturerect_card.position = parent_hboxcontainer_card.position	
	texturerect_card.custom_minimum_size = card_size
	texturerect_card.expand = true
	texturerect_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	label_portal_reload.visible = false
	Engine.time_scale = 1.0
	current_health = player_max_health
	_set_spell_currently(spell_currently_index)
	progressbar_mana.step = 1
	take_mana(progressbar_mana.max_value)
	progressbar_reload_spell.step = 0.1
	progressbar_reload_spell.value = time_reload_spell
	progressbar_reload_spell.max_value = time_reload_spell
	_on_health_changed(player_max_health)
	connect("health_changed", _on_health_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP && event.pressed:
			if texturerect_card.visible:
				if card_list.size() > 1:
					if texturerect_card.texture:
						hboxcontainer_card.get_child(card_currently_index).texture = texturerect_card.texture
					card_currently_index -=1
					if card_currently_index < 0:
						card_currently_index = card_list.size() - 1
					set_card_new_position(card_currently_index)
			else:
				spell_currently_index -=1
				if spell_currently_index < 0:
					spell_currently_index = spells.size() - 1
				_set_spell_currently(spell_currently_index)
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN && event.pressed:
			if texturerect_card.visible:
				if card_list.size() > 1:
					if texturerect_card.texture:
						hboxcontainer_card.get_child(card_currently_index).texture = texturerect_card.texture
					card_currently_index +=1
					if card_currently_index == card_list.size():
						card_currently_index = 0
					set_card_new_position(card_currently_index)
			else:
				spell_currently_index +=1
				if spell_currently_index == spells.size():
					spell_currently_index = 0
				_set_spell_currently(spell_currently_index)
		elif event.button_index ==MOUSE_BUTTON_MIDDLE && event.pressed:
			texturerect_card.visible = !texturerect_card.visible
			if texturerect_card.visible:
				card_currently_index = 0
				if card_list.size() > 0:
					set_card_new_position(card_currently_index)
			else:
				if card_list.size() > 0:
					hboxcontainer_card.get_child(card_currently_index).texture = texturerect_card.texture
				texturerect_card.texture = null
		elif  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if texturerect_card.visible:
				if texturerect_card.texture:
					remove_card()				 
			elif timer_reload_spell.is_stopped():
				if spells[spell_currently_index].spell_name.to_lower() == "thunderbolt":
					create_spell(prefathunderbolt.instantiate())				
				elif spells[spell_currently_index].spell_name.to_lower() == "waterball":
					create_spell(prefabwaterball.instantiate())				
				elif spells[spell_currently_index].spell_name.to_lower() == "tornado":
					create_spell(prefabtornado.instantiate())			
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

func _set_spell_currently(index):
	texturerect_overlay.texture = get_spell_texture(spells[index].spell_name)
	label_mana_cost.text = str(int(spells[index].mana_cost))
	
func create_spell(prefab: Node3D):
	if progressbar_mana.value - spells[spell_currently_index].mana_cost < 0:
		pass
	else:
		prefab.spell = spells[spell_currently_index]
		prefab.player = self	
		prefab.set_collider(raycast.get_collider(), raycast.get_collision_point())
		world.add_child(prefab)
		prefab.global_transform.origin = raycast.global_transform.origin
		prefab.global_transform.basis = raycast.global_transform.basis
		timer_reload_spell.start()
		progressbar_reload_spell.value = 0
		take_mana(-spells[spell_currently_index].mana_cost)
		
func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, player_max_health)  # Zapobiega przekroczeniu zakresu zdrowia
	emit_signal("health_changed", current_health)
	if !is_alive():
		get_tree().call_deferred("reload_current_scene")

func take_heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, player_max_health)
	emit_signal("health_changed", current_health)
	
func take_mana(amount: int):
	progressbar_mana.value = clamp(progressbar_mana.value + amount, 0, progressbar_mana.max_value)
	label_mana.text = str(int(progressbar_mana.value)) + "/" + str(int(progressbar_mana.max_value))

func is_alive() -> bool:
	return current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func _on_timer_reload_spell_timeout() -> void:
	var value = progressbar_reload_spell.value + timer_reload_spell.wait_time
	if value >= progressbar_reload_spell.max_value:
		progressbar_reload_spell.value = progressbar_reload_spell.max_value
		timer_reload_spell.stop()
	else:
		progressbar_reload_spell.value = value

func portal_free(portal) -> void:
	world.list_portal_set_position.append(portal)
	if world.list_portal_set_position.size() == world.create_portal_count:
		label_portal_reload.text = "%02d" % time_reload_portal
		label_portal_reload.set_deferred("visible", true)
		time_currently_reload_portal = time_reload_portal
		timer_portal_reload.start()

func _on_timer_portal_reload_timeout() -> void:
	time_currently_reload_portal -= timer_portal_reload.wait_time
	label_portal_reload.text = "%02d" % time_currently_reload_portal
	if time_currently_reload_portal < 0.001:		
		world.timer_height_scan_start()
		timer_portal_reload.stop()
		label_portal_reload.set_deferred("visible", false)

func card_list_update()->void:
	var width = card_list.size() * card_size.x
	hboxcontainer_card.remove_theme_constant_override("separation")
	if width > parent_hboxcontainer_card.size.x:
		var separation = (width - parent_hboxcontainer_card.size.x)/(card_list.size()-1)
		hboxcontainer_card.add_theme_constant_override("separation", -round(separation + 0.5))
	else:
		hboxcontainer_card.add_theme_constant_override("separation", 0)

func get_card_texture(card_name: String)->Texture2D:
	match card_name:
		"card_mana_potion": return card_mana_potion 
		"card_hp_potion": return card_hp_potion
		"card_mana_max_increase": return card_mana_max_increase
		"card_mana_max": return card_mana_max
		_: return null		
		
func get_spell_texture(sell_name: String)->Texture2D:
	match sell_name:
		"thunderbolt": return spell_thunderbolt 
		"tornado": return spell_tornado
		"waterball": return spell_waterball
		_: return null		
	
func set_card_new_position(index)->void:
	var card = hboxcontainer_card.get_child(index)
	texturerect_card.position = Vector2(parent_hboxcontainer_card.position.x + clamp(card.position.x, 0, parent_hboxcontainer_card.size.x - texturerect_card.size.x), parent_hboxcontainer_card.position.y - texturerect_card.size.y)
	texturerect_card.texture = card.texture	
	card.texture = null
	card.custom_minimum_size = card_size
						
func add_card()->void:
	var card_name = card_all_list_enemy[randi_range(0, card_all_list_enemy.size()-1)]
	card_list.append(card_name)
	var card = TextureRect.new()
	card.custom_minimum_size = card_size
	card.expand = true
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	card.texture = get_card_texture(card_name)
	card_list_update()	
	if hboxcontainer_card.get_child_count() == 0:
		hboxcontainer_card.add_child(card)
		card_currently_index = 0
		if texturerect_card.visible:
			set_card_new_position(card_currently_index)
	else:	
		hboxcontainer_card.add_child(card)
	
func remove_card()->void:	
	match card_list[card_currently_index]:
		"card_mana_potion": take_mana(card_mana_potion_mana_increase)
		"card_hp_potion": take_heal(card_hp_potion_hp_increase)
		"card_mana_max_increase": 
			progressbar_mana.max_value +=1
			take_mana(0)
		"card_mana_max": take_mana(progressbar_mana.max_value)
	card_list.remove_at(card_currently_index)
	hboxcontainer_card.remove_child(hboxcontainer_card.get_child(card_currently_index))
	texturerect_card.texture = null	
	if card_currently_index == card_list.size():
		card_currently_index -= 1
	card_list_update()
	if card_currently_index >-1:
		call_deferred("set_card_new_position", card_currently_index)
