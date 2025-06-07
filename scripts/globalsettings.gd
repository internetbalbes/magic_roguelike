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
		"enemy_pivot_rotation_speed": 200.0,
		"count_segments_around_portal": 36,
		"probability_modificator": 25,
		"probability_modificator_maximum": 75,
		"probability_modificator_increase": 5,
	},
	"zombie": {
		"label_health_max_value": 3,
		"size_blood_on_floor": Vector3(3.0, 3.0, 3.0),
		"enemy_radius_around_portal": 20.0,
		"enemy_speed_walk": 1,
		"enemy_speed_run": 10,
		"time_to_beat": 0.45,
		"probability_card": 100,
		"damage": 1,
		"enemy_area_scan_player": 2.25,
		"enemy_transform_scale": 1.25,
		"enemy_texture": preload("res://prefabs/enemies/zombie/zombie_model-zombie_model.png")
	},
	"imp": {
		"label_health_max_value": 3,
		"size_blood_on_floor": Vector3(3.0, 3.0, 3.0),
		"enemy_speed_walk": 1,
		"enemy_speed_run": 10,
		"enemy_radius_around_portal": 10.0,
		"time_to_beat": 0.9,
		"time_to_set_trap": 2.0,
		"time_after_exit_portal": 3.0,
		"enemy_area_scan_player": 45,
		"probability_card": 100,
		"enemy_transform_scale": 1.25,
		"enemy_texture": preload("res://prefabs/enemies/imp/akaki-akaki.png")
	},
	"boss": {
		"label_health_max_value": 1,
		"size_blood_on_floor": Vector3(3.0, 3.0, 3.0),
		"enemy_speed_run": 14,
		"time_to_beat": 0.7,
		"probability_card": 100,
		"damage": 1,
		"enemy_area_scan_player": 3,
		"enemy_transform_scale": 1.5,
		"setor_damage": 45,
		"count_direction_damage":4,
		"radius_sector_damage_min": 3,
		"radius_sector_damage_max": 6,
		"enemy_texture": preload("res://prefabs/enemies/kishi/kishi.png")
	},
	"skymage": {
		"label_health_max_value": 3,
		"size_blood_on_floor": Vector3(3.0, 3.0, 3.0),
		"enemy_speed_walk": 2,
		"enemy_distance_from_portal": 5,
		"time_to_beat": 5.0,
		"probability_card": 100,
		"enemy_transform_scale": 1.5,
		"enemy_texture": preload("res://prefabs/enemies/skymage/sky_mage.png")
	}	
}

var cards_hint = {
	"card_mana_potion": "mana potion's card",
	"card_hp_potion": "hp potion's card",
	"card_mana_max_increase": "mana max increase's card",
	"card_mana_max": "mana max's card",
	"card_hp_to_mana_sacrifice": "hp to mana sacrifice's card",
	"card_mine_spell": "mine spell's card",
	"card_freeze": "freeze spell's card"	
}

var cold_steels = {
	"pivot_rotation_speed": 200.0,
	"one_handed_sword":{
		"damage"=3,
		"targets"=1,
		"cooldown"=1.16,
		"texture" = load("res://sprites/items/one_handed_sword.png"),
		"prefab" = load("res://prefabs/objects/one_handed_sword/one_handed_sword.tscn") 
	},
	"one_handed_axe":{
		"damage"=1,
		"targets"=1,
		"cooldown"=1.16,
		"texture"= load("res://sprites/items/one_handed_axe.png"),
		"prefab"= load("res://prefabs/objects/one_handed_axe/one_handed_axe.tscn")
	}	
}
	
var rune_param = {
	"pivot_rotation_speed": 0,
	"splash_targets_amount_increase" :{
		"parameter": "targets",
		"value": 1,
		"texture": load("res://sprites/runes/splash_rune.png")
	}
}

var interaction_info = {
		"drop_interaction_hint_text": "Press 'X' to pick up",
		"warning_is_in_fog_hint_text": "You are in a fog. GO BACK !!!"
	}
	
var player_param = {
	"player_speed_walk": 8,
	"player_max_health": 10,
	"player_max_mana": 15,
	"player_jump_velocity": 3,
	"player_rotate_sensitivity": 0.085,
	"player_scan_enemy": 30,
	"time_reload_spell": 0.1,
	"player_speed_walk_slowing": 0.1,
	"player_speed_time_slowing": 0.6
}

var spells_param = {
	"waterball_spell_mana_cost": 1,
	"waterball_spell_damage": 1,
	"waterball_spell_type": "sphere",
	"thunderbolt_spell_mana_cost": 2,
	"thunderbolt_spell_damage": 3,
	"thunderbolt_spell_type": "single",
	"tornado_spell_mana_cost": 1,
	"tornado_spell_damage": 1,
	"tornado_spell_type": "sphere",
	"trap_spell_mana_cost": 3,
	"trap_spell_damage": 2,
	"trap_spell_type": "sphere",
	"freeze_spell_mana_cost": 1,
	"freeze_spell_damage": 0,
	"freeze_spell_type": "single",
	"card_mana_potion_mana_increase": 5,
	"card_hp_potion_hp_increase": 5,
	"card_hp_to_mana_sacrifice_exchange": 5
}

var cards_param = {
	"card_mana_potion_mana_increase": 5,
	"card_hp_potion_hp_increase": 5,
	"card_hp_to_mana_sacrifice_exchange": 5
}

var player_coldsteel = {
	"detection_angle_deg_near_enemy": 60,
	"detection_distance_near_enemy": 2.0
}

var enemy_imp_fireball = {
	"enemy_fireball_speed": 50,
	"enemy_fireball_time_life": 2,
	"enemy_fireball_damage": 1
}	

var enemy_skymage_sphere = {
	"skymage_sphere_time_life": 1.5,
	"skymage_sphere_radius": 5,
	"skymage_sphere_damage": 1,
	"skymage_sphere_reload_time": 3.0
}

var player_waterball = {
	"player_waterball_speed": 40,
	"player_waterball_time_life": 1.0,
	"player_waterball_radius": 5
}

var player_thunderbolt = {
	"player_thunderbolt_time_life": 1.0,
	"player_thunderbol_radius": 10
}

var player_tornado = {
	"player_tornado_speed": 40,
	"player_tornado_shoot_time_life": 1,
	"player_tornado_time_life": 4,
	"player_tornado_radius": 9
}

var player_trap = {
	"player_trap_radius": 7
}

var player_freeze = {
	"player_freeze_time_effect": 1.0,
	"player_freeze_time_life": 5.0,
	"player_freeze_radius": 10
}

var portal = {
	"portal_create_new_enemy_count": 2,
	"portal_create_new_enemy_time": 15,
	"portal_create_new_enemy_groupe_count": 6,
	"area_observe_radius": 20.0
}
		
var enemy_spawn_rate = {
	"imp": 20,
	"skymage": 20,
	"zombie":  60
}

var world_param = {
	"scale_size_map": 50,
	"portal_create_enemy_count": 5,
	"portal_reload_enemy_increase": 3
}
