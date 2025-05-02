extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var image_pointcatch = $interface/aim
@onready var timer_reload_spell = $timer_reload_spell
@onready var timer_reload_coldsteel = $timer_reload_coldsteel
@onready var collision_shape: Shape3D = $CollisionShape3D.shape
@onready var label_health = $interface/hp/hp
@onready var progressbar_reload_coldsteel = $interface/progressbar_reload_coldsteel
@onready var progressbar_reload_spell = $interface/spells/book/progressbar_reload_spell
@onready var progressbar_mana = $interface/mana/progressbar_mana
@onready var label_mana = $interface/mana/progressbar_mana/labelmana
@onready var texturerect_base = $interface/spells/book
@onready var texturerect_overlay = $interface/spells/book/spell_icon
@onready var label_mana_cost = $interface/spells/mana_cost
@onready var parent_hboxcontainer_card = $interface/Control
@onready var hboxcontainer_card = $interface/Control/hboxcontainer_card
@onready var texturerect_card: TextureRect = $interface/texturerect_card
@onready var coldsteel: Node3D = $coldsteel

@export var prefathunderbolt : PackedScene
@export var prefabwaterball : PackedScene
@export var prefabtornado : PackedScene
@export var prefabtrap : PackedScene
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
# player's currently health
var player_current_health: int = player_max_health
# time reload spell
var time_reload_spell = 1.0
# time reload coldspeel
var time_reload_coldspeel = 1.0
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
var spell_trap = preload("res://sprites/trap_icon.png")
var texturerect_card_set = Vector2.ZERO
#list file cards
var card_all_list_enemy: Array = ["card_mana_potion", "card_hp_potion", "card_mana_max_increase", "card_hp_to_mana_sacrifice"]
var card_mana_potion = preload("res://sprites/card_mana_potion.png") 
var card_hp_potion = preload("res://sprites/card_hp_potion.png")
var card_mana_max_increase = preload("res://sprites/card_mana_max_increase.png")
var card_mana_max = preload("res://sprites/card_mana_max.png")
var card_hp_to_mana_sacrifice = preload("res://sprites/card_hp_to_mana_sacrifice.png")
var card_scale = 2
var card_size = card_scale * Vector2(32, 48)
var card_currently_index = -1
var card_list : Array
var card_list_animation : Array
var card_mana_potion_mana_increase = 2
var card_hp_potion_hp_increase = 2
var card_hp_to_mana_sacrifice_exchange = 2

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
		time_reload_coldspeel = config.get_value("player", "time_reload_coldspeel", time_reload_coldspeel)		
		time_reload_portal = config.get_value("player", "time_reload_portal", time_reload_portal)
		progressbar_mana.max_value =  config.get_value("player", "player_max_mana", 10)
		raycast.target_position.z =  -config.get_value("player", "player_scan_enemy", abs(raycast.target_position.z))
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
		# spell tornado
		mana_cost = config.get_value("spells", "trap_spell_mana_cost", 1)
		damage = config.get_value("spells", "trap_spell_damage", 1)
		type = config.get_value("spells", "trap_spell_type", "sphere")
		spell = SpellClass.new("trap", mana_cost, damage, type)
		spells.append(spell)		
		#cards
		card_mana_potion_mana_increase  = config.get_value("cards", "card_mana_potion_mana_increase", card_mana_potion_mana_increase)
		card_hp_potion_hp_increase  = config.get_value("cards", "card_hp_potion_hp_increase", card_hp_potion_hp_increase)
		card_hp_to_mana_sacrifice_exchange = config.get_value("cards", "card_hp_to_mana_sacrifice_exchange", card_hp_to_mana_sacrifice_exchange)
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
	Engine.time_scale = 1.0
	player_current_health = player_max_health
	_set_spell_currently(spell_currently_index)
	progressbar_mana.step = 1
	take_mana(progressbar_mana.max_value)
	progressbar_reload_spell.step = 0.1
	progressbar_reload_spell.value = time_reload_spell
	progressbar_reload_spell.max_value = time_reload_spell
	progressbar_reload_coldsteel.step = 0.1
	progressbar_reload_coldsteel.value = time_reload_coldspeel
	progressbar_reload_coldsteel.max_value = time_reload_coldspeel	
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
			if texturerect_card.visible:
				if card_list.size() > 0:
					hboxcontainer_card.get_child(card_currently_index).texture = texturerect_card.texture
				texturerect_card.texture = null
				texturerect_card.visible = false
			elif card_list.size() > 0:
				texturerect_card.visible = true
				card_currently_index = 0
				set_card_new_position(card_currently_index)
		elif  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if texturerect_card.visible:
				if texturerect_card.texture:
					remove_card()
			elif timer_reload_spell.is_stopped():
				var spell = spells[spell_currently_index]
				if progressbar_mana.value - spell.mana_cost < 0:
					pass
				elif spell.spell_name.to_lower() == "thunderbolt":
					create_spell(prefathunderbolt.instantiate())
				elif spell.spell_name.to_lower() == "waterball":
					create_spell(prefabwaterball.instantiate())
				elif spell.spell_name.to_lower() == "tornado":
					create_spell(prefabtornado.instantiate())
				elif state != playerstate.JUMPING && spell.spell_name.to_lower() == "trap":
					create_trap()
		elif  event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			timer_reload_coldsteel.start()
			progressbar_reload_coldsteel.value = 0
			coldsteel.action_cold_steel(raycast.get_collider(), raycast.get_collision_point(), "single")					
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
	prefab.spell = spells[spell_currently_index]
	prefab.player = self	
	prefab.set_collider(raycast.get_collider(), raycast.get_collision_point(), abs(raycast.target_position.z))
	world.add_child(prefab)
	prefab.global_transform.origin = raycast.global_transform.origin
	prefab.global_transform.basis = raycast.global_transform.basis
	reload_spell()
	
func create_trap():
	var prefab = prefabtrap.instantiate()
	prefab.spell = spells[spell_currently_index]
	world.add_child(prefab)
	var direction = Vector3(0, collision_shape.height / 2, 0.5).normalized()
	prefab.global_transform.origin = global_transform.origin - direction
	reload_spell()
		
func reload_spell():
	timer_reload_spell.start()
	progressbar_reload_spell.value = 0
	take_mana(-spells[spell_currently_index].mana_cost)	
	
func take_damage(amount: int):
	player_current_health -= amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)
	if !is_alive():
		get_tree().call_deferred("reload_current_scene")

func take_heal(amount: int):
	player_current_health += amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)
	
func take_mana(amount: int):
	progressbar_mana.value = clamp(progressbar_mana.value + amount, 0, progressbar_mana.max_value)
	label_mana.text = str(int(progressbar_mana.value)) + "/" + str(int(progressbar_mana.max_value))

func is_alive() -> bool:
	return player_current_health > 0

func _on_health_changed(new_health: int):	
	label_health.text = str(new_health)  # Skalowanie wartości na pasek zdrowia

func _on_timer_reload_spell_timeout() -> void:
	var value = progressbar_reload_spell.value + timer_reload_spell.wait_time
	if value >= progressbar_reload_spell.max_value:
		progressbar_reload_spell.value = progressbar_reload_spell.max_value
		timer_reload_spell.stop()
	else:
		progressbar_reload_spell.value = value

func portal_free() -> void:
	create_card("card_mana_max")

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
		"card_hp_to_mana_sacrifice": return card_hp_to_mana_sacrifice
		_: return null		
		
func get_spell_texture(sell_name: String)->Texture2D:
	match sell_name:
		"thunderbolt": return spell_thunderbolt 
		"tornado": return spell_tornado
		"waterball": return spell_waterball
		"trap": return spell_trap
		_: return null		
	
func set_card_new_position(index)->void:
	var card = hboxcontainer_card.get_child(index)
	texturerect_card.position = Vector2(parent_hboxcontainer_card.position.x + clamp(card.position.x, 0, parent_hboxcontainer_card.size.x - texturerect_card.size.x), parent_hboxcontainer_card.position.y - texturerect_card.size.y)
	texturerect_card.texture = card.texture	
	card.texture = null
	card.custom_minimum_size = card_size
						
func add_card()->void:
	var card_name = card_all_list_enemy[randi_range(0, card_all_list_enemy.size()-1)]
	create_card(card_name)	

func create_card(card_name)->void:
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
		"card_mana_potion": 
			if progressbar_mana.max_value - progressbar_mana.value > 0.1:
				take_mana(card_mana_potion_mana_increase)
			else:
				return
		"card_hp_potion": 
			if player_max_health - player_current_health > 0.1:
				take_heal(card_hp_potion_hp_increase)
			else:
				return			
		"card_mana_max_increase": 
			progressbar_mana.max_value +=1
			take_mana(0)
		"card_mana_max": 
			if progressbar_mana.max_value - progressbar_mana.value > 0.1:
				take_mana(progressbar_mana.max_value)
			else:
				return
		"card_hp_to_mana_sacrifice":
			if player_current_health - card_hp_to_mana_sacrifice_exchange > 1:
				var exchange = card_hp_to_mana_sacrifice_exchange
				if progressbar_mana.value + exchange > progressbar_mana.max_value:
					exchange = progressbar_mana.max_value - progressbar_mana.value				
				take_mana(exchange)
				take_damage(exchange)
			else:
				return
	card_list.remove_at(card_currently_index)
	hboxcontainer_card.remove_child(hboxcontainer_card.get_child(card_currently_index))
	texturerect_card.texture = null	
	if card_currently_index == card_list.size():
		card_currently_index -= 1
	card_list_update()
	if card_currently_index >-1:
		call_deferred("set_card_new_position", card_currently_index)
	else:
		texturerect_card.visible = false

func _on_timer_reload_coldsteel_timeout() -> void:
	var value = progressbar_reload_coldsteel.value + timer_reload_coldsteel.wait_time
	if value >= progressbar_reload_coldsteel.max_value:
		progressbar_reload_coldsteel.value = progressbar_reload_coldsteel.max_value
		timer_reload_coldsteel.stop()
	else:
		progressbar_reload_coldsteel.value = value
