extends Node3D

@onready var audiostream = $AudioStreamPlayer3D
@onready var map = $map
@onready var sun = $map/DirectionalLight3D
@onready var map_relief =$map/relief
@onready var environment = $map/WorldEnvironment.environment  # Pobieramy Environment
@onready var sky = environment.sky
@onready var sky_material = sky.sky_material
@onready var audio_stream = $AudioStreamPlayer3D
@onready var fires = $map/fires
@onready var player = $player

@export var prefabfire : PackedScene
@export var random_fire_count = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 50)
		var volume_db = volume * 80 / 100.0 - 80.0  # Konwersja do skali decybeli (-80 dB to cisza)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)				
	_generation_fire()		
	audio_stream.play()	

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	
		
func _generation_fire():
	var aabb = map_relief.get_aabb().size / 2
	# Skalujemy za pomocą metody scaled
	for i in range(0, random_fire_count, 1):
		var obj = prefabfire.instantiate()
		obj.prefabenemy = load("res://prefabs/enemy.tscn")  # Ścieżka do prefaba
		obj.player = player
		fires.add_child(obj)
		var pos : Vector3# = aabb
		pos.x = map.scale.x * randf_range(-aabb.x, aabb.x)
		pos.z = map.scale.z * randf_range(-aabb.z, aabb.z)
		pos.y = aabb.y
		#pos = Vector3(cos(deg_to_rad(i*60)), 0, sin(deg_to_rad(i*60))) * 10
		obj.global_position = pos
		print(obj.global_position)
		#obj.rotate_y(deg_to_rad(i * 60))
		
func _remowe_fire():
	while fires.get_child_count() > 0:
		var obj = fires.get_child(fires.get_child_count()-1)
		fires.remove_child(obj)
		obj.queue_free()
			
	
