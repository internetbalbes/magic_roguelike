extends Node3D

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

var chunk_array = []

class tile:
	var relief = ""
	var corner_y_rotate = 0

func _ready() -> void:
	chunk_array_expansion()
	
func chunk_array_expansion():
	for i in range(CHUNK_SIZE):
		chunk_array.append([])
		for j in range(CHUNK_SIZE):
			chunk_array[i].append(tile.new())
			chunk_array[i][j].relief = ""

func create_chunk():
	clear_chunk_array()
	create_path()
	create_corners()
	visualize_chunk()
	create_portal()
	create_barrier()
	chunks_clearing()	
	call_deferred("bake_navigation_mesh")
	transform_chunk()
	chunks_created_amount += 1
		
func clear_chunk_array():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			chunk_array[x][y].relief = "block"

var random_index : int
var painter_position = Vector2i()
var chunks_created_amount : int = 0
var last_y_list = []

func create_path():
	if chunks_created_amount == 0:
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
	chunk_list.append(created_prefab)
	created_prefab.name = "chunk_" + str(chunks_created_amount)
	add_child(created_prefab)	

func create_tile(id):
	created_prefab = tile_prefab.instantiate()
	created_prefab.name = "tile_" + id
	chunk_list[-1].add_child(created_prefab)
	current_tile = created_prefab

var random_tile_index : Vector2i

var created_portal

func create_portal():
	created_prefab = portal_prefab.instantiate()
	created_prefab.position = Vector3(CHUNK_SIZE - 1,0,last_y_list[-1])
	created_prefab.name = "portal_" + str(CHUNK_SIZE - 1) + "_" + str(last_y_list[-1])
	created_prefab.scale *=0.03
	current_tile.add_child(created_prefab)
	created_portal = created_prefab

var SCALE_SIZE_MAP = 1

func transform_chunk():
	chunk_list[-1].position.x = CHUNK_SIZE * chunks_created_amount * SCALE_SIZE_MAP
	chunk_list[-1].scale *= SCALE_SIZE_MAP

func chunks_clearing():
	if chunks_created_amount > 2:
		var old_chunk = chunk_list.pop_front()
		if old_chunk:
			old_chunk.queue_free()

var HALF_CHUNK_SIZE = SCALE_SIZE_MAP / 2.0

func find_block_free():
	return Vector3((1 - HALF_CHUNK_SIZE + 0.5) * SCALE_SIZE_MAP,0,(1 - HALF_CHUNK_SIZE + 0.5) * SCALE_SIZE_MAP)

func portal_destroyed():
	created_portal.queue_free()
	current_barrier.queue_free()
	create_chunk()

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


var barrier_prefab = load("res://map_generator/prefabs/barrier/barrier.tscn")
var current_barrier
	
func create_barrier():
	created_prefab = barrier_prefab.instantiate()
	created_prefab.position = Vector3(CHUNK_SIZE-1,0.5,last_y_list[-1])
	created_prefab.name = "barrier"
	current_barrier = created_prefab
	current_tile.add_child(created_prefab)		
	
