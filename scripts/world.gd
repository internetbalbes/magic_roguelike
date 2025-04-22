extends Node3D

@onready var audiostream = $AudioStreamPlayer3D
@onready var map = $map
@onready var map_relief =$map/relief
@onready var height_scan = $height_scan
@onready var timer_height_scan = $timer_height_scan
@onready var audio_stream = $AudioStreamPlayer3D
@onready var player = $player
@export var prefabportal : PackedScene

#generation count portals on a map
var create_portal_count = 5
#list portals for set on a map
var list_portal_set_position : Array
#scale map's size to set portal
var scale_size_map_to_set_portal = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 50)
		var volume_db = volume * 80 / 100.0 - 80.0  # Konwersja do skali decybeli (-80 dB to cisza)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
		create_portal_count = config.get_value("world", "create_portal_count", create_portal_count)
		scale_size_map_to_set_portal = config.get_value("world", "scale_size_map_to_set_portal", 4)
		#config.save("res://settings.cfg")
	config = null
	while  list_portal_set_position.size() < create_portal_count:
		var obj = prefabportal.instantiate()
		list_portal_set_position.append(obj)		
		obj.prefabenemy = load("res://prefabs/enemy.tscn")  # Ścieżka do prefaba
		obj.player = player
		obj.world = self
		add_child(obj)
		obj.portal_process_stop()
	timer_height_scan_start()
	audio_stream.play()	

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	
		
func _on_timer_height_scan_timeout() -> void:
	if height_scan.is_colliding():
		var obj = height_scan.get_collider()
		if obj:
			var shape = obj.get_parent()
			if shape == map_relief:
				var portal = list_portal_set_position[0]
				portal.global_position = height_scan.get_collision_point()
				portal.portal_process_start()
				list_portal_set_position.remove_at(0)
				if list_portal_set_position.size() == 0:
					return
	timer_height_scan_start()

func timer_height_scan_start():
	var aabb = map_relief.get_aabb().size / scale_size_map_to_set_portal
	height_scan.target_position.x = map.scale.x * randf_range(-aabb.x, aabb.x)
	height_scan.target_position.z = map.scale.z * randf_range(-aabb.z, aabb.z)
	timer_height_scan.start()
