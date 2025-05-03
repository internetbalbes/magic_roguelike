extends NavigationRegion3D

var portal_prefab = load("res://map_generator/prefabs/portal/portal.tscn")
var ground_prefab = load("res://map_generator/prefabs/ground.tscn")
var chunk_prefab = load("res://map_generator/prefabs/chunk.tscn")
var block_prefab = load("res://map_generator/prefabs/block.tscn")

var CHUNK_SIZE = 7
var HALF_CHUNK_SIZE = CHUNK_SIZE / 2.0	

var chunks_created_amount : int = 0

var chunk_array = []

var chunk_list = []

var last_y_list = []

var created_portal
var scale_size_map = 50.0

func _ready() -> void:	
	chunk_array_expansion()	

func create_chunk():
	chunk_array_clear()
	create_chunk_prefab()
	create_ground()
	create_path()
	visualize_blocks_and_create_barriers()
	create_portal()
	chunks_created_amount += 1
	chunks_clearing()
	create_navigation()
	
func create_chunk_prefab():
	var created_chunk = chunk_prefab.instantiate()
	chunk_list.append(created_chunk)
	add_child(created_chunk)

func chunk_array_expansion():
	for i in range(CHUNK_SIZE):
		chunk_array.append([])
		for j in range(CHUNK_SIZE):
			chunk_array[i].append("BLOCK")	

func create_ground():
	var created_ground = ground_prefab.instantiate()
	created_ground.position.x = chunks_created_amount * CHUNK_SIZE * scale_size_map
	created_ground.scale *= CHUNK_SIZE * scale_size_map
	chunk_list[-1].add_child(created_ground)
	
func create_portal():
	while true:
		var random_chunk_array_index = Vector2i(randi_range(1,CHUNK_SIZE-2),randi_range(1,CHUNK_SIZE-2))
		if chunk_array[random_chunk_array_index.x][random_chunk_array_index.y] == "FREE":
			created_portal = portal_prefab.instantiate()
			created_portal.position.x = (random_chunk_array_index.x - HALF_CHUNK_SIZE + (CHUNK_SIZE * chunks_created_amount) + 0.5)*scale_size_map
			created_portal.position.z = (random_chunk_array_index.y - HALF_CHUNK_SIZE + 0.5)*scale_size_map			
			chunk_list[-1].add_child(created_portal)			
			break

func find_block_free():
	for x in range(1, CHUNK_SIZE-1, 1):
		for y in range(1, CHUNK_SIZE-1, 1):			
			if chunk_array[x][y] == "FREE":
				var result= Vector3.ZERO
				result.x = (x - HALF_CHUNK_SIZE + 0.5)*scale_size_map
				result.z = (y - HALF_CHUNK_SIZE + 0.5)*scale_size_map
				result.y = 0
				return result	
			
func portal_destroyed():
	created_portal.queue_free()
	create_chunk()

func create_navigation():
	call_deferred("bake_navigation_mesh")

func create_path():
	var random_index : int
	var painter_position = Vector2i()
	
	if chunks_created_amount == 0:
		painter_position = Vector2i(1,1)
	else:
		painter_position = Vector2i(1,last_y_list[-1])
		chunk_array[0][painter_position.y] = "FREE"
	
	chunk_array[painter_position.x][painter_position.y] = "FREE"	
		
	while painter_position.x != CHUNK_SIZE- 1:
		random_index = randi_range(0,4)
		match random_index:
			0:painter_position.x += 1
			1:
				if painter_position.y != CHUNK_SIZE - 2:
					painter_position.y += 1
			2:
				if painter_position.y != 1:
					painter_position.y -= 1
			3:
				if painter_position.x != 1:
					painter_position.x -= 1
					
		chunk_array[painter_position.x][painter_position.y] = "FREE"
		
	last_y_list.append(painter_position.y)
	
func visualize_blocks_and_create_barriers():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y] == "BLOCK":
				var created_block = block_prefab.instantiate()
				created_block.position = scale_size_map * Vector3(x - HALF_CHUNK_SIZE + (CHUNK_SIZE * chunks_created_amount) + 0.5,0.5,y - HALF_CHUNK_SIZE + 0.5)
				created_block.scale *=scale_size_map
				chunk_list[-1].add_child(created_block)

func chunk_array_clear():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			chunk_array[x][y] = "BLOCK"

func chunks_clearing():
	if chunks_created_amount > 2:
		for chunk in chunk_list:
			if chunk != null:
				chunk.queue_free()
				break
