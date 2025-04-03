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
	audio_stream.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_of_day += delta / day_length  # Przesuwamy czas w zależności od trwania dnia
	if time_of_day > 1.0:
		time_of_day = 0.0  # Zresetuj czas, jeśli minął pełny cykl
	 # Zmieniamy kąt Słońca na podstawie czasu dnia
	var sun_angle = lerp(0, 360, time_of_day)  # Przesuwamy Słońce od -90 do 270 stopni
	sun_angle = 0
	sun.rotation_degrees.x = sun_angle
	if sun_angle > 180 && sun_angle < 360:
		if  !audio_stream.playing:
			audio_stream.play()
			_remowe_fire()
	else:
		if  audio_stream.playing:
			audio_stream.stop()
			_generation_fire()
			

func _generation_fire():
	var aabb = map_relief.get_aabb().size
	for i in range(1, random_fire_count, 1):
		var obj = prefabfire.instantiate()
		fires.add_child(obj)
		var pos = aabb
		pos.x = randf_range(0.0, aabb.x)
		pos.z = randf_range(0.0, aabb.z)
		pos.y = -0.5
		obj.global_position = pos
		
func _remowe_fire():
	while fires.get_child_count() > 0:
		fires.get_child(fires.get_child_count()-1).queue_free()
			
	
