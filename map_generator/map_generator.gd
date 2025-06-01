extends Node3D

@onready var kill_zone: Area3D = $kill_zone

const ENVIRONMENT_OBJECTS = {
	"tree10" = {
		"prefab_path" = "res://map_generator/prefabs/ground/tree/tree10/tree_10.tscn",
		"amount_per_tile" = 5,
		"amount_per_chunk" = 0,
		"scale" = 0.05
	},
	"well" = {
		"prefab_path" = "res://map_generator/prefabs/well/well.tscn",
		"amount_per_tile" = 1,
		"amount_per_chunk" = 0,
		"scale" = 0.03
	},
	"campfire" = {
		"prefab_path" = "res://map_generator/prefabs/campfire/campfire.tscn",
		"amount_per_tile" = 1,
		"amount_per_chunk" = 0,
		"scale" = 0.02
	}
}

const CHUNK_SIZE = 4

var HALF_CHUNK_SIZE = CHUNK_SIZE / 2.0
var SCALE_SIZE_MAP = 1
var chunk_array = []

class tile:
	var relief = ""
	var corner_y_rotate = 0

func _ready() -> void:
	kill_zone.visible = false
	chunk_array_expansion()
	
func chunk_array_expansion():
	for i in range(CHUNK_SIZE):
		chunk_array.append([])
		for j in range(CHUNK_SIZE):
			chunk_array[i].append(tile.new())
			chunk_array[i][j].relief = ""

func create_map():
	create_portal()
	create_chunk(created_portal, null, false)
	create_chunk(null, create_kill_zone("kill_zone_forward"), true)	
	
func create_chunk(portal, zone, bake):
	clear_chunk_array()
	create_path()
	create_corners()
	visualize_chunk()
	if zone:
		if zone.get_parent():
			zone.reparent(chunk_list[-1])
		else:
			chunk_list[-1].add_child(zone)
	if portal:
		portal.position = Vector3(CHUNK_SIZE - 1, 0, last_y_list[-1])	
		chunk_list[-1].add_child(portal)
	transform_chunk()
	chunks_clearing()
	if bake:
		call_deferred("bake_navigation_mesh")

func create_kill_zone(zone_name):
	var _kill_zone = kill_zone.duplicate()
	_kill_zone.position = Vector3(HALF_CHUNK_SIZE,  0.0,  HALF_CHUNK_SIZE)
	_kill_zone.name = zone_name
	var fog = _kill_zone.get_node("fog")
	fog.size = Vector3(CHUNK_SIZE,  1.0,  CHUNK_SIZE)
	_kill_zone.visible = true	
	fog.material.set_shader_parameter("length_x", CHUNK_SIZE)
	_kill_zone.get_node("CollisionShape3D").shape.size = fog.size
	return _kill_zone

func clear_chunk_array():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			chunk_array[x][y].relief = "block"

var random_index : int
var painter_position = Vector2i()
var last_y_list = []

func create_path():
	if chunk_list.size() == 0:
		painter_position = Vector2i(1, 1)
	else:
		painter_position = Vector2i(1, last_y_list[-1])
		chunk_array[0][painter_position.y].relief = "ground"
		
	chunk_array[painter_position.x][painter_position.y].relief = "ground"
	
	while painter_position.x != CHUNK_SIZE - 1:
		random_index = randi_range(0, 4)
		match random_index:
			0:
				painter_position.x += 1
			1:
				if painter_position.y != CHUNK_SIZE - 2:
					painter_position.y += 1
			2:
				if painter_position.y != 1:
					painter_position.y -= 1
			3:
				if painter_position.x != 1:
					painter_position.x -= 1

		chunk_array[painter_position.x][painter_position.y].relief = "ground"
		
	last_y_list.append(painter_position.y)

var created_prefab
var chunk_list = []
var ground_prefab = load("res://map_generator/prefabs/ground/ground.tscn")
var chunk_prefab = load("res://map_generator/prefabs/ground/chunk_prefab/chunk.tscn")
var block_prefab = load("res://map_generator/prefabs/block/block.tscn")
var tile_prefab = load("res://map_generator/prefabs/ground/tile_prefab/tile.tscn")
var portal_prefab = load("res://map_generator/prefabs/portal/portal.tscn")
var current_tile

func visualize_chunk():
	create_chunk_prefab()
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			create_tile(str(x) + "_" + str(y))
			match chunk_array[x][y].relief:
				"ground":
					created_prefab = ground_prefab.instantiate()
					created_prefab.position = Vector3(x,0,y)
					created_prefab.name = "ground"
					current_tile.add_child(created_prefab)
					create_environment(x,y)
				"block":
					created_prefab = block_prefab.instantiate()
					created_prefab.position = Vector3(x,-0.375,y)
					created_prefab.name = "block_" + str(x) + "_" + str(y)
					current_tile.add_child(created_prefab)
				"corner":
					create_corner(x,y,chunk_array[x][y].corner_y_rotate)
				"corner_connector":
					create_corner_connector(x,y,chunk_array[x][y].corner_y_rotate)	
							
func create_chunk_prefab():
	created_prefab = chunk_prefab.instantiate()
	created_prefab.name = "chunk_" + str(chunk_list.size())	
	chunk_list.append(created_prefab)
	add_child(created_prefab)	

func create_tile(id):
	created_prefab = tile_prefab.instantiate()
	created_prefab.name = "tile_" + id
	chunk_list[-1].add_child(created_prefab)
	current_tile = created_prefab

var random_tile_index : Vector2i

var created_portal

func create_portal():
	created_portal = portal_prefab.instantiate()
	created_portal.name = "portal"
	created_portal.scale *=0.03

func transform_chunk():
	chunk_list[-1].position.x = CHUNK_SIZE * (chunk_list.size() - 1) * SCALE_SIZE_MAP
	chunk_list[-1].scale *= SCALE_SIZE_MAP

func chunks_clearing():
	if chunk_list.size() > 4:
		var old_chunk = chunk_list.pop_front()
		if old_chunk:
			old_chunk.queue_free()

func find_block_free():
	return Vector3((HALF_CHUNK_SIZE - 0.5) , 0, 1.0) * SCALE_SIZE_MAP

func portal_destroyed():
	var _transform = Transform3D.IDENTITY
	var zone : Node3D
	if chunk_list.size() == 4:
		zone = chunk_list[0].get_node("kill_zone_back")
		_transform = zone.transform
		zone.reparent(chunk_list[1])
		zone.transform = _transform
	elif chunk_list.size() == 3:
		chunk_list[0].add_child(create_kill_zone("kill_zone_back"))
	_transform = created_portal.transform
	created_portal.reparent(chunk_list[-1])
	created_portal.transform = _transform
	created_portal.position = Vector3(CHUNK_SIZE - 1, 0, last_y_list[-1])
	zone = chunk_list[-1].get_node("kill_zone_forward")
	_transform = zone.transform
	create_chunk(null, zone, true)
	zone.transform = _transform
	
var corner_prefab = load("res://map_generator/prefabs/corner/corner.tscn")

func create_corners():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y].relief == "block":
				# Проверяем все 4 стороны и задаём угол поворота
				if x + 1 <= CHUNK_SIZE - 1 and chunk_array[x + 1][y].relief == "ground":
					chunk_array[x][y].relief = "corner"
					chunk_array[x][y].corner_y_rotate = 0
				elif y - 1 >= 0 and chunk_array[x][y - 1].relief == "ground":
					chunk_array[x][y].relief = "corner"
					chunk_array[x][y].corner_y_rotate = 90
				elif x - 1 >= 0 and chunk_array[x - 1][y].relief == "ground":
					chunk_array[x][y].relief = "corner"
					chunk_array[x][y].corner_y_rotate = 180
				elif y + 1 <= CHUNK_SIZE - 1 and chunk_array[x][y + 1].relief == "ground":
					chunk_array[x][y].relief = "corner"
					chunk_array[x][y].corner_y_rotate = 270

func create_corner(x,y,y_rotate):
	created_prefab = corner_prefab.instantiate()
	created_prefab.position = Vector3(x,0.0625,y)
	created_prefab.name = "corner_" + str(x) + "_" + str(y)
	created_prefab.rotation_degrees.y = y_rotate
	current_tile.add_child(created_prefab)
	
var corner_connector_prefab = load("res://map_generator/prefabs/corner_connector/corner_connector.tscn")

func create_corner_connector(x,y,y_rotate):
	created_prefab = corner_connector_prefab.instantiate()
	created_prefab.position = Vector3(x,0.0625,y)
	created_prefab.name = "corner_connector_" + str(x) + "_" + str(y)
	created_prefab.rotation_degrees.y = y_rotate
	current_tile.add_child(created_prefab)
	
var environment_object
var object_data
var random_chunk_array_index = Vector2i()

func create_environment(x,y):
	for object in ENVIRONMENT_OBJECTS:
		object_data = ENVIRONMENT_OBJECTS[object]
		environment_object = load(object_data["prefab_path"])
		
		if chunk_array[x][y].relief == "ground" and Vector2i(x,y) != Vector2i(CHUNK_SIZE-1,last_y_list[-1]):
			for a in object_data["amount_per_tile"]:
				created_prefab = environment_object.instantiate()
				created_prefab.position = Vector3(randf_range(x-0.5,x+0.5),0,randf_range(y-0.5,y+0.5))
				created_prefab.name = object + "_" + str(created_prefab.position.x) + "_" + str(created_prefab.position.y)
				created_prefab.scale *= object_data["scale"]
				current_tile.add_child(created_prefab)

func set_collision_kill_zone(collision_layer):
	var zone = chunk_list[-1].get_node("kill_zone_forward")
	zone.collision_mask = zone.collision_mask * collision_layer	

func _on_kill_zone_body_entered(body: Node3D) -> void:
	if body.has_method("in_kill_zone"):
		body.in_kill_zone()	


func _on_kill_zone_body_exited(body: Node3D) -> void:
	if body.has_method("out_kill_zone"):
		body.out_kill_zone()	
