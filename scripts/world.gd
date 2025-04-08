extends Node3D

@onready var audiostream = $AudioStreamPlayer3D
@onready var map = $map
@onready var map_relief =$map/relief
@onready var audio_stream = $AudioStreamPlayer3D
@onready var player = $player
@onready var height_scan = $height_scan
@onready var timer_height_scan = $timer_height_scan

@export var prefabfire : PackedScene
@export var random_fire_count = 5

var currently_fire_count = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 50)
		var volume_db = volume * 80 / 100.0 - 80.0  # Konwersja do skali decybeli (-80 dB to cisza)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	timer_height_scan.start()
	audio_stream.play()	

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _on_timer_height_scan_timeout() -> void:
	if height_scan.is_colliding():
		var shape = height_scan.get_collider().get_parent()
		if shape == map_relief:
			var obj = prefabfire.instantiate()
			obj.prefabenemy = load("res://prefabs/enemy.tscn")  # Ścieżka do prefaba
			obj.player = player
			obj.world = self
			add_child(obj)
			obj.global_position = height_scan.get_collision_point()
			currently_fire_count += 1	
	if currently_fire_count < random_fire_count:	
		var aabb = map_relief.get_aabb().size / 4
		height_scan.target_position.x = map.scale.x * randf_range(-aabb.x, aabb.x)
		height_scan.target_position.z = map.scale.z * randf_range(-aabb.z, aabb.z)
		timer_height_scan.start()
