extends CharacterBody3D

const SWORD_SPLASH_TRAIL_MAX_POINTS = 100
const SWORD_SPLASH_TRAIL_WIDTH = 0.15 * 200

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var timer_reload_spell: Timer = $timer_reload_spell
@onready var timer_reload_coldsteel = $timer_reload_coldsteel
@onready var collision_shape: Shape3D = $CollisionShape3D.shape
@onready var coldsteel: Node3D = $coldsteel
@onready var animation_player: AnimationPlayer = $Camera3D/player_model/AnimationPlayer
@onready var timer_walk_slowing: Timer = $timer_walk_slowing

@onready var image_pointcatch = $interface/VBoxContainer/aim
@onready var label_health = $interface/HUD/health_sphere/hp
@onready var progressbar_reload_coldsteel = $interface/VBoxContainer/progressbar_reload_coldsteel
@onready var label_mana = $interface/HUD/mana_sphere/mana
@onready var texturerect_base = $interface/HUD/book
@onready var texturerect_overlay = $interface/HUD/book/spell_icon
@onready var label_mana_cost = $interface/HUD/book/mana_cost
@onready var parent_hboxcontainer_card = $interface/HUD/wallet
@onready var hboxcontainer_card = $interface/HUD/wallet/hboxcontainer_card
@onready var texturerect_card: TextureRect = $interface/texturerect_card
@onready var card_hint: Label = $interface/card_hint
@onready var label_enemy_appear_count = $interface/HUD/enemy_appear/enemy_count
@onready var label_enemy_appear_time = $interface/HUD/enemy_appear/enemy_time
@onready var label_enemy_appear_spawn = $interface/HUD/enemy_appear/enemy_spawn
@onready var label_hp_sphere = $interface/HUD/health_sphere
@onready var label_hp_sphere_fill = $interface/HUD/health_sphere/SubViewport/sphere_outside/sphere_inside
@onready var label_mana_sphere = $interface/HUD/mana_sphere
@onready var label_mana_sphere_fill =$interface/HUD/mana_sphere/SubViewport/sphere_outside/sphere_inside

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
# time reload coldspeel
var time_reload_coldspeel = 1.0
# speed scroll_container spells
var spell_currently_index = 1
# player's max mana 
var player_max_mana  = 10
# player's currently mana 
var player_currently_mana = player_max_mana
#list file spels
var spell_thunderbolt = preload("res://sprites/thunderbolt.png") 
var spell_waterball = preload("res://sprites/waterball_icon.png")
var spell_tornado = preload("res://sprites/tornado_icon.png")
var spell_trap = preload("res://sprites/trap_icon.png")
var texturerect_card_set = Vector2.ZERO
#list file cards
var card_all_list_enemy: Array = ["card_mana_potion", "card_hp_potion", "card_mana_max_increase", "card_hp_to_mana_sacrifice", "card_mine_spell"]
var card_mana_potion = preload("res://sprites/card_mana_potion.png") 
var card_hp_potion = preload("res://sprites/card_hp_potion.png")
var card_mana_max_increase = preload("res://sprites/card_mana_max_increase.png")
var card_mana_max = preload("res://sprites/card_mana_max.png")
var card_hp_to_mana_sacrifice = preload("res://sprites/card_hp_to_mana_sacrifice.png")
var card_mine_spell = preload("res://sprites/card_mine_spell.png")
var card_scale = 3
var card_size = card_scale * Vector2(32, 48)
var card_currently_index = -1
var card_list : Array
var card_mana_potion_mana_increase = 2
var card_hp_potion_hp_increase = 2
var card_hp_to_mana_sacrifice_exchange = 2
var sword_splash_animation_time = 0.0
var player_speed_walk_slowing = 1.0
var is_card_dissolve_tween: bool = false

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_speed_walk = config.get_value("player", "player_speed_walk", player_speed_walk)
		player_max_health = config.get_value("player", "player_max_health", player_max_health)
		player_jump_velocity = config.get_value("player", "player_jump_velocity", player_jump_velocity)
		player_rotate_sensitivity = config.get_value("player", "player_rotate_sensitivity", player_rotate_sensitivity)
		timer_reload_spell.wait_time = config.get_value("player", "time_reload_spell", 1.0)
		time_reload_coldspeel = config.get_value("player", "time_reload_coldspeel", time_reload_coldspeel)		
		player_max_mana =  config.get_value("player", "player_max_mana", player_max_mana)
		raycast.target_position.z =  -config.get_value("player", "player_scan_enemy", abs(raycast.target_position.z))
		player_speed_walk_slowing = config.get_value("player", "player_speed_walk_slowing", player_speed_walk_slowing)
		timer_walk_slowing.wait_time = config.get_value("player", "player_speed_time_slowing", timer_walk_slowing.wait_time)
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
	sword_splash_animation_time = 1.16 / animation_player.speed_scale
	card_hint.visible = false
	texturerect_card.visible = false
	texturerect_card.size = Vector2(card_size.x, card_size.y)
	var rect = Vector2(8 * card_size.x, card_size.y)
	parent_hboxcontainer_card.set_deferred("size", rect) 
	var window_size = camera.get_viewport().get_visible_rect().size
	var top = window_size.y - rect.y
	var left = (window_size.x - rect.x) / 2.0	
	parent_hboxcontainer_card.position = Vector2(left, top)	
	texturerect_card.position = parent_hboxcontainer_card.position	
	texturerect_card.custom_minimum_size = card_size
	texturerect_card.expand = true
	texturerect_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT	
	var mat = label_hp_sphere_fill.get_material_override() 
	mat.set_shader_parameter("base_color", Vector3(1.0, 0.0, 0.0))	
	top = window_size.y - label_hp_sphere.size.y * label_hp_sphere.get_parent().scale.y
	left = left - label_hp_sphere.size.x * label_hp_sphere.get_parent().scale.y	
	label_hp_sphere.get_parent().position = Vector2(left, top)	
	mat = label_mana_sphere_fill.get_material_override() 
	mat.set_shader_parameter("base_color", Vector3(0.0, 0.0, 1.0))
	left = parent_hboxcontainer_card.position.x + rect.x	
	label_mana_sphere.get_parent().position = Vector2(left, top)
	texturerect_card.material.set_shader_parameter("dissolve_value", 1.0)
	take_health(player_max_health)
	_set_spell_currently(spell_currently_index)
	take_mana(player_max_mana)
	progressbar_reload_coldsteel.step = 0.05
	progressbar_reload_coldsteel.value = time_reload_coldspeel
	progressbar_reload_coldsteel.max_value = time_reload_coldspeel
	label_health.text = str(int(player_current_health)) + "/" + str(int(player_max_health))
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
				card_hint.visible = false
			elif card_list.size() > 0:
				texturerect_card.visible = true
				card_hint.visible = true
				card_currently_index = 0
				set_card_new_position(card_currently_index)
		elif  event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			if timer_reload_spell.is_stopped():
				var spell = spells[spell_currently_index]
				if player_currently_mana - spell.mana_cost < 0:
					pass
				elif spell.spell_name.to_lower() == "thunderbolt":
					var collider = raycast.get_collider()
					if collider && collider.is_in_group("enemy"):
						create_spell(prefathunderbolt.instantiate())
				elif spell.spell_name.to_lower() == "waterball":
					create_spell(prefabwaterball.instantiate())
				elif spell.spell_name.to_lower() == "tornado":
					create_spell(prefabtornado.instantiate())
				elif state != playerstate.JUMPING && spell.spell_name.to_lower() == "trap":
					create_trap()
		elif  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if texturerect_card.visible:
				if texturerect_card.texture && not is_card_dissolve_tween:
					remove_card()
			elif timer_reload_coldsteel.is_stopped():
				timer_reload_coldsteel.start()
				progressbar_reload_coldsteel.value = 0
				animation_player.play("melee")
	elif event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * player_rotate_sensitivity))

func _physics_process(delta: float) -> void:
	# find collide with object
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider && (collider.is_in_group("portal") || collider.is_in_group("enemy")):
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
	prefab._set_global_transform(raycast.global_transform)
	animation_player.play("cast")
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
	take_mana(-spells[spell_currently_index].mana_cost)	

func take_health(amount: int):
	player_current_health = clamp(player_current_health + amount, 0, player_max_health)
	label_health.text = str(int(player_current_health)) + "/" + str(int(player_max_health))	
	var mat = label_hp_sphere_fill.get_material_override() 
	mat.set_shader_parameter("fill", player_current_health / float(player_max_health))

func take_damage(amount: int):
	if player_current_health > 0:
		take_health(-amount)
		if !is_alive():
			animation_player.stop()
			get_tree().call_deferred("reload_current_scene")
		elif timer_walk_slowing.is_stopped():
			player_speed_walk *= player_speed_walk_slowing
			timer_walk_slowing.start()	

func take_mana(amount: int):
	player_currently_mana = clamp(player_currently_mana + amount, 0, player_max_mana)
	label_mana.text = str(int(player_currently_mana)) + "/" + str(int(player_max_mana))
	var mat = label_mana_sphere_fill.get_material_override() 
	mat.set_shader_parameter("fill", player_currently_mana / float(player_max_mana))

func is_alive() -> bool:
	return player_current_health > 0

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
		"card_mine_spell": return card_mine_spell
		_: return null
		
func get_card_hint(card_name: String):
	match card_name:
		"card_mana_potion": return Globalsettings.cards_hint["card_mana_potion"]
		"card_hp_potion": return Globalsettings.cards_hint["card_hp_potion"]
		"card_mana_max_increase": return Globalsettings.cards_hint["card_mana_max_increase"]
		"card_mana_max": return Globalsettings.cards_hint["card_mana_max"]
		"card_hp_to_mana_sacrifice": return Globalsettings.cards_hint["card_hp_to_mana_sacrifice"]
		"card_mine_spell": return Globalsettings.cards_hint["card_mine_spell"]
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
	card_hint.text = get_card_hint(card_list[index])
	card_hint.position = Vector2(texturerect_card.position.x + texturerect_card.size.x + 10, texturerect_card.position.y + (texturerect_card.size.y - card_hint.size.y) / 2)  
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
			if player_max_mana - player_currently_mana > 0.1:
				take_mana(card_mana_potion_mana_increase)
			else:
				return
		"card_hp_potion": 
			if player_max_health - player_current_health > 0.1:
				take_health(card_hp_potion_hp_increase)
			else:
				return			
		"card_mana_max_increase": 
			player_max_mana +=1
			take_mana(0)
		"card_mana_max": 
			if player_max_mana - player_currently_mana > 0.1:
				take_mana(player_max_mana)
			else:
				return
		"card_hp_to_mana_sacrifice":
			if player_current_health - card_hp_to_mana_sacrifice_exchange > 1:
				var exchange = card_hp_to_mana_sacrifice_exchange
				if player_currently_mana + exchange > player_max_mana:
					exchange = player_max_mana - player_currently_mana
				take_mana(exchange)
				take_health(-exchange)
			else:
				return
		"card_mine_spell":
			create_trap()	
	is_card_dissolve_tween = true
	var card_tween = create_tween()
	card_tween.tween_property(texturerect_card.material, "shader_parameter/dissolve_value", 0.0, .5)
	await card_tween.finished
	texturerect_card.material.set_shader_parameter("dissolve_value", 1.0)
	is_card_dissolve_tween = false
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
		card_hint.visible = false

func _on_timer_reload_coldsteel_timeout() -> void:
	var value = progressbar_reload_coldsteel.value + timer_reload_coldsteel.wait_time
	if value >= progressbar_reload_coldsteel.max_value:
		progressbar_reload_coldsteel.value = progressbar_reload_coldsteel.max_value
		timer_reload_coldsteel.stop()
		coldsteel.action_cold_steel_cutoff_off(false)
	else:
		if value > 0.5 / animation_player.speed_scale && value < 0.7 / animation_player.speed_scale:
			if !coldsteel.is_action_cold_steel_cutoff():
				coldsteel.action_cold_steel(raycast.get_collider(), raycast.get_collision_point(), "single")
		else:
			coldsteel.action_cold_steel_cutoff_off(false)
		progressbar_reload_coldsteel.value = value

# enemy's appear count 
func _set_enemy_appear_count(value):
	label_enemy_appear_count.text = str(value)
	
func enemy_appear_time(value):
	label_enemy_appear_time.text = str(int(value))

func enemy_appear_spawn(value):
	label_enemy_appear_spawn.text = str(int(value))

func _on_timer_walk_slowing_timeout() -> void:
	player_speed_walk /= player_speed_walk_slowing
