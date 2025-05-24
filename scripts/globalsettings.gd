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
		"enemy_pivot_rotation_speed": 1.0,
		"count_segments_around_portal": 0,
		"probability_modificator": 0,
		"probability_modificator_maximum": 0,
		"probability_modificator_increase": 0
	},
	"zombie": {
		"label_health_max_value": 0,
		"size_blood_on_floor": Vector3.ZERO,
		"enemy_radius_around_portal": 0.0,
		"enemy_speed_walk": 0.0,
		"enemy_speed_run": 0.0,
		"time_to_beat": 0.0,
		"probability_card": 0.0,
		"damage": 0.0,
		"enemy_area_scan_player": 0.0,
		"enemy_transform_scale": 0.0	
	},
	"imp": {
		"label_health_max_value": 0,
		"size_blood_on_floor": Vector3.ZERO,
		"enemy_speed_walk": 0.0,
		"enemy_speed_run": 0.0,
		"enemy_radius_around_portal": 0.0,
		"time_to_throw": 0.0,
		"time_to_set_trap": 0.0,
		"time_after_exit_portal": 0.0,
		"enemy_area_scan_player": 0.0,
		"probability_card": 0.0,
		"enemy_transform_scale": 0.0
	},
	"boss": {
		"label_health_max_value": 0,
		"size_blood_on_floor": Vector3.ZERO,
		"enemy_speed": 0,
		"time_to_beat": 0,
		"probability_card": 0,
		"probability_modificator": 0,
		"damage": 0,
		"enemy_area_scan_player": 0,
		"enemy_transform_scale": 0,
	},
	"skymage": {
		"label_health_max_value": 0,
		"size_blood_on_floor": Vector3.ZERO,
		"enemy_speed": 0,
		"enemy_distance_from_portal": 0,
		"time_to_throw": 0,
		"probability_card": 0,
		"enemy_transform_scale": 0
	}	
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		
		enemy_param["common"]["probability_modificator"] =  config.get_value("enemy_common", "probability_modificator", enemy_param["common"]["probability_modificator"])
		enemy_param["common"]["probability_modificator_maximum"] =  config.get_value("enemy_common", "probability_modificator_maximum", enemy_param["common"]["probability_modificator_maximum"])
		enemy_param["common"]["probability_modificator_increase"] =  config.get_value("enemy_common", "probability_modificator_increase", enemy_param["common"]["probability_modificator_increase"])
		
		enemy_param["common"]["enemy_pivot_rotation_speed"] = config.get_value("enemy_common", "enemy_pivot_rotation_speed", enemy_param["common"]["enemy_pivot_rotation_speed"])
		enemy_param["common"]["count_segments_around_portal"] = config.get_value("enemy_common", "count_segments_around_portal", enemy_param["common"]["count_segments_around_portal"])		
		
		enemy_param["zombie"]["label_health_max_value"] = randi_range(1, config.get_value("enemy_zombie", "enemy_max_health", enemy_param["zombie"]["label_health_max_value"]))
		enemy_param["zombie"]["size_blood_on_floor"] = Vector3(config.get_value("enemy_zombie", "size_blood_on_floor_x", enemy_param["zombie"]["size_blood_on_floor"].x),
														config.get_value("enemy_zombie", "size_blood_on_floor_y", enemy_param["zombie"]["size_blood_on_floor"].y),
														config.get_value("enemy_zombie", "size_blood_on_floor_z", enemy_param["zombie"]["size_blood_on_floor"].z))
		enemy_param["zombie"]["enemy_radius_around_portal"] = config.get_value("enemy_zombie", "enemy_radius_around_portal", enemy_param["zombie"]["enemy_radius_around_portal"])
														
		enemy_param["zombie"]["enemy_speed_walk"] = config.get_value("enemy_zombie", "enemy_speed_walk", enemy_param["zombie"]["enemy_speed_walk"])
		enemy_param["zombie"]["enemy_speed_run"] = config.get_value("enemy_zombie", "enemy_speed_run", enemy_param["zombie"]["enemy_speed_run"])
		enemy_param["zombie"]["time_to_beat"] = config.get_value("enemy_zombie", "time_to_beat", enemy_param["zombie"]["time_to_beat"])
		enemy_param["zombie"]["probability_card"] = config.get_value("enemy_zombie", "probability_card", enemy_param["zombie"]["probability_card"])
		enemy_param["zombie"]["damage"] = config.get_value("enemy_zombie", "damage", enemy_param["zombie"]["damage"])
		enemy_param["zombie"]["enemy_area_scan_player"] = config.get_value("enemy_zombie", "enemy_area_scan_player", enemy_param["zombie"]["enemy_area_scan_player"])
		enemy_param["zombie"]["enemy_transform_scale"] = config.get_value("enemy_zombie", "enemy_transform_scale",  enemy_param["zombie"]["enemy_transform_scale"])
		
		enemy_param["imp"]["label_health_max_value"] = randi_range(1, config.get_value("enemy_imp", "enemy_max_health", enemy_param["imp"]["label_health_max_value"]))
		enemy_param["imp"]["size_blood_on_floor"] = Vector3(config.get_value("enemy_imp", "size_blood_on_floor_x", enemy_param["imp"]["size_blood_on_floor"].x),
														config.get_value("enemy_imp", "size_blood_on_floor_y", enemy_param["imp"]["size_blood_on_floor"].y),
														config.get_value("enemy_imp", "size_blood_on_floor_z", enemy_param["imp"]["size_blood_on_floor"].z))														
		enemy_param["imp"]["enemy_speed_walk"] = config.get_value("enemy_imp", "enemy_speed_walk", enemy_param["imp"]["enemy_speed_walk"])
		enemy_param["imp"]["enemy_speed_run"] = config.get_value("enemy_imp", "enemy_speed_run", enemy_param["imp"]["enemy_speed_run"])
		enemy_param["imp"]["enemy_radius_around_portal"] = config.get_value("enemy_imp", "enemy_radius_around_portal", enemy_param["imp"]["enemy_radius_around_portal"])
		enemy_param["imp"]["time_to_throw"] = config.get_value("enemy_imp", "time_to_throw", enemy_param["imp"]["time_to_throw"])
		enemy_param["imp"]["time_to_set_trap"] = config.get_value("enemy_imp", "time_to_set_trap", enemy_param["imp"]["time_to_set_trap"])		
		enemy_param["imp"]["time_after_exit_portal"] = config.get_value("enemy_imp", "time_after_exit_portal", enemy_param["imp"]["time_after_exit_portal"])
		enemy_param["imp"]["enemy_area_scan_player"] = config.get_value("enemy_imp", "enemy_area_scan_player", enemy_param["imp"]["enemy_radius_around_portal"])
		enemy_param["imp"]["probability_card"] =  config.get_value("enemy_imp", "probability_card", enemy_param["imp"]["probability_card"])
		enemy_param["imp"]["enemy_transform_scale"] = config.get_value("enemy_imp", "enemy_transform_scale",  enemy_param["imp"]["enemy_transform_scale"])
		
		enemy_param["boss"]["label_health_max_value"] = config.get_value("enemy_boss", "enemy_max_health", enemy_param["boss"]["label_health_max_value"])
		enemy_param["boss"]["size_blood_on_floor"] = Vector3(config.get_value("enemy_boss", "size_blood_on_floor_x", enemy_param["boss"]["size_blood_on_floor"].x),
														config.get_value("enemy_boss", "size_blood_on_floor_y", enemy_param["boss"]["size_blood_on_floor"].y),
														config.get_value("enemy_boss", "size_blood_on_floor_z", enemy_param["boss"]["size_blood_on_floor"].z))
		enemy_param["boss"]["enemy_speed"] = config.get_value("enemy_boss", "enemy_speed", enemy_param["boss"]["enemy_speed"])
		enemy_param["boss"]["time_to_beat"] = config.get_value("enemy_boss", "time_to_beat", enemy_param["boss"]["time_to_beat"])
		enemy_param["boss"]["probability_card"] =  config.get_value("enemy_boss", "probability_card", enemy_param["boss"]["probability_card"])
		enemy_param["boss"]["damage"] = config.get_value("enemy_boss", "damage", enemy_param["boss"]["damage"])
		enemy_param["boss"]["enemy_area_scan_player"] = config.get_value("enemy_boss", "enemy_area_scan_player", enemy_param["boss"]["enemy_area_scan_player"])
		enemy_param["boss"]["enemy_transform_scale"] = config.get_value("enemy_boss", "enemy_transform_scale", enemy_param["boss"]["enemy_transform_scale"])
		
		enemy_param["skymage"]["label_health_max_value"] = randi_range(1, config.get_value("enemy_skymage", "enemy_max_health", enemy_param["skymage"]["label_health_max_value"]))
		enemy_param["skymage"]["size_blood_on_floor"] = Vector3(config.get_value("enemy_skymage", "size_blood_on_floor_x", enemy_param["skymage"]["size_blood_on_floor"].x),
														config.get_value("enemy_skymage", "size_blood_on_floor_y", enemy_param["skymage"]["size_blood_on_floor"].y),
														config.get_value("enemy_skymage", "size_blood_on_floor_z", enemy_param["skymage"]["size_blood_on_floor"].z))
		enemy_param["skymage"]["enemy_speed"] = config.get_value("enemy_skymage", "enemy_speed", enemy_param["skymage"]["enemy_speed"])
		enemy_param["skymage"]["enemy_distance_from_portal"] = config.get_value("enemy_skymage", "enemy_distance_from_portal", enemy_param["skymage"]["enemy_distance_from_portal"])
		enemy_param["skymage"]["time_to_throw"] = config.get_value("enemy_skymage", "time_to_throw", enemy_param["skymage"]["time_to_throw"])
		enemy_param["skymage"]["probability_card"] =  config.get_value("enemy_skymage", "probability_card", enemy_param["skymage"]["probability_card"])	
		enemy_param["skymage"]["enemy_transform_scale"] = config.get_value("enemy_skymage", "enemy_transform_scale",  enemy_param["skymage"]["enemy_transform_scale"])
		
	config = null
