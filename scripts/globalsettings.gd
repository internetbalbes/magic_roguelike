extends Node

# array of all modificators
var enemy_list_modificators = {
	"water_resist": {"texture": load("res://sprites/water_resist_icon.png")},
	"magic_resist": {"texture": load("res://sprites/magic_resist_icon.png")}
}

# array of all bufs
var enemy_list_bufs = {
	"wet": {"texture": load("res://sprites/wet_icon.png")}
}

var enemy_param = {
	"common":{
		"enemy_pivot_rotation_speed": 1.0
	},
	"zombie": {
		"label_health_max_value": 3
	},
	"imp": {
		"label_health_max_value": 3
	},
	"boss": {
		"label_health_max_value": 3
	},
	"skymage": {
		"label_health_max_value": 3
	}	
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_param["common"]["enemy_pivot_rotation_speed"] = config.get_value("enemy_common", "enemy_pivot_rotation_speed", enemy_param["common"]["enemy_pivot_rotation_speed"])
		enemy_param["zombie"]["label_health_max_value"] = randi_range(1, config.get_value("enemy_zombie", "enemy_max_health", enemy_param["zombie"]["label_health_max_value"]))
		#config.save("res://settings.cfg")
	config = null
