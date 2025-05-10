extends Node3D

const CHUNK_SIZE = 7

var chunk_array = []

class tile:
	var relief = ""
	var corner_y_rotate = 0

func _ready() -> void:
	chunk_array_expansion()
	create_chunk()
	
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
	chunks_created_amount += 1
	chunks_clearing()
	
	call_deferred("bake_navigation_mesh")
		
	transform_chunk()
		
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
				"block":
					created_prefab = block_prefab.instantiate()
					created_prefab.position = Vector3(x,0,y)
					created_prefab.name = "block_" + str(x) + "_" + str(y)
					current_tile.add_child(created_prefab)
				"corner":
					create_corner(x,y,chunk_array[x][y].corner_y_rotate)
							
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
	current_tile.add_child(created_prefab)
	created_portal = created_prefab

const SCALE_SIZE_MAP = 1

func transform_chunk():
	chunk_list[-1].position.x = CHUNK_SIZE * chunks_created_amount * SCALE_SIZE_MAP
	chunk_list[-1].scale *= SCALE_SIZE_MAP

func chunks_clearing():
	if chunks_created_amount > 2:
		var old_chunk = chunk_list.pop_front()
		if old_chunk:
			old_chunk.queue_free()

const HALF_CHUNK_SIZE = SCALE_SIZE_MAP / 2.0

func find_block_free():
	return Vector3((1 - HALF_CHUNK_SIZE + 0.5) * SCALE_SIZE_MAP,0,(1 - HALF_CHUNK_SIZE + 0.5) * SCALE_SIZE_MAP)

func portal_destroyed():
	created_portal.queue_free()
	create_chunk()

var corner_prefab = load("res://map_generator/prefabs/corner/corner.tscn")

func create_corners():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y].relief == "block":
				if x + 1 <= CHUNK_SIZE - 1 and chunk_array[x + 1][y].relief == "ground":
					chunk_array[x][y].relief = "corner"
				elif x - 1 >= 0 and chunk_array[x - 1][y].relief == "ground":
					chunk_array[x][y].relief = "corner"
				elif y + 1 <= CHUNK_SIZE - 1 and chunk_array[x][y + 1].relief == "ground":
					chunk_array[x][y].relief = "corner"
				elif y - 1 >= 0 and chunk_array[x][y - 1].relief == "ground":
					chunk_array[x][y].relief = "corner"
					
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y].relief == "corner":
				if x + 1 <= CHUNK_SIZE - 1 and chunk_array[x + 1][y].relief == "ground":
					chunk_array[x][y].corner_y_rotate = 0
				elif x - 1 >= 0 and chunk_array[x - 1][y].relief == "ground":
					chunk_array[x][y].corner_y_rotate = 0
				elif y + 1 <= CHUNK_SIZE - 1 and chunk_array[x][y + 1].relief == "ground":
					chunk_array[x][y].corner_y_rotate = 0
				elif y - 1 >= 0 and chunk_array[x][y - 1].relief == "ground":
					chunk_array[x][y].corner_y_rotate = 0


func create_corner(x,y,y_rotate):
	created_prefab = corner_prefab.instantiate()
	created_prefab.position = Vector3(x,0,y)
	created_prefab.name = "corner_" + str(x) + "_" + str(y)
	created_prefab.rotation_degrees.y = y_rotate
	current_tile.add_child(created_prefab)
