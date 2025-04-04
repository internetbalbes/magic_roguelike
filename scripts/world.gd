extends Node3D

@onready var audiostream = $AudioStreamPlayer3D
@onready var map = $map
@onready var sun = $map/DirectionalLight3D
@onready var environment = $map/WorldEnvironment.environment  # Pobieramy Environment
@onready var sky = environment.sky
@onready var sky_material = sky.sky_material
@onready var audio_stream = $AudioStreamPlayer3D
@onready var fires = $map/fires
@onready var map_relief =$map/relief
@onready var map_moon =$moon

@export var prefabfire : PackedScene
@export var random_fire_count = 5

var time_of_day = 0.5  # 0.0 = początek dnia, 1.0 = koniec dnia (pełny cykl 24h)
var day_length = 60.0  # Czas trwania pełnego cyklu dnia i nocy (w sekundach)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 50)
		var volume_db = volume * 80 / 100.0 - 80.0  # Konwersja do skali decybeli (-80 dB to cisza)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)		
	#audio_stream.play()	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_of_day += delta / day_length  # Przesuwamy czas w zależności od trwania dnia
	if time_of_day > 1.0:
		time_of_day = 0.0  # Zresetuj czas, jeśli minął pełny cykl
	 # Zmieniamy kąt Słońca na podstawie czasu dnia
	var sun_angle = lerp(0, 360, time_of_day)  # Przesuwamy Słońce od -90 do 270 stopni
	sun.rotation_degrees.x = sun_angle
	if sun_angle > 180 && sun_angle < 360:
		if  !audio_stream.playing:
			audio_stream.play()
			map_moon.visible =false
			_remowe_fire()
	else:
		if  audio_stream.playing:
			audio_stream.stop()
			map_moon.visible =true
			_generation_fire()
			

func _generation_fire():
	var aabb = map_relief.get_aabb().size / 2
	# Skalujemy za pomocą metody scaled
	for i in range(0, random_fire_count, 1):
		var obj = prefabfire.instantiate()
		fires.add_child(obj)
		var pos = aabb
		pos.x = map.scale.x * randf_range(-aabb.x, aabb.x)
		pos.z = map.scale.z * randf_range(-aabb.z, aabb.z)		
		#pos = Vector3.ZERO + Vector3(cos(deg_to_rad(i*60)), 0, sin(deg_to_rad(i*60))) * 10
		obj.global_position = pos
		#obj.rotate_y(deg_to_rad(i * 60))
		
func _remowe_fire():
	while fires.get_child_count() > 0:
		var obj = fires.get_child(fires.get_child_count()-1)
		fires.remove_child(obj)
		obj.queue_free()
			
	
