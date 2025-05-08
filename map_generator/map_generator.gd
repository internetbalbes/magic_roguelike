extends NavigationRegion3D

var portal_prefab = load("res://map_generator/prefabs/portal/portal.tscn")
var ground_prefab = load("res://map_generator/prefabs/ground/ground.tscn")
var chunk_prefab = load("res://map_generator/prefabs/chunk.tscn")
var block_prefab = load("res://map_generator/prefabs/block/block.tscn")
var stone_prefab = load("res://map_generator/prefabs/stone/stone.tscn")
var corner_prefab = load("res://map_generator/prefabs/corner/corner.tscn")
var corner_connector_prefab = load("res://map_generator/prefabs/corner_connector/corner_connector.tscn")

var grass_plane_prefab = load("res://map_generator/prefabs/ground/grass_plane/grass_plane.tscn")

var tree10_prefab = load("res://map_generator/prefabs/ground/tree/tree10/tree10.tscn")
var dead_tree_prefab = load("res://map_generator/prefabs/ground/tree/dead/dead_tree.tscn")

var bush08_prefab = load("res://map_generator/prefabs/ground/bush/bush08.tscn")

var CHUNK_SIZE = 5
var HALF_CHUNK_SIZE = CHUNK_SIZE / 2.0

var chunks_created_amount : int = 0

var chunk_array = []

var chunk_list = []

var last_y_list = []

var timer_bake_wait : Timer = Timer.new()

var created_portal
var created_prefab
var scale_size_map = 50.0

var portal_position_in_array : Vector2i

func _ready() -> void:
	timer_bake_wait.one_shot = 1.0
	timer_bake_wait.timeout.connect(_on_timer_bake_wait_timeout)	
	add_child(timer_bake_wait)
	chunk_array_expansion()

func create_chunk():
	chunk_array_clear()
	create_path_with_portal() # Изменено название функции, чтобы отразить добавление портала в путь
	create_chunk_prefab()
	create_ground()
	visualize_blocks_and_create_barriers()
	create_portal()
	create_environment()
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
	if portal_position_in_array != null:
		created_portal = portal_prefab.instantiate()
		created_portal.position.x = (portal_position_in_array.x - HALF_CHUNK_SIZE + (CHUNK_SIZE * chunks_created_amount) + 0.5) * scale_size_map
		created_portal.position.z = (portal_position_in_array.y - HALF_CHUNK_SIZE + 0.5) * scale_size_map
		chunk_list[-1].add_child(created_portal)
	else:
		printerr("Error: Portal position not defined in the chunk array.")

func find_block_free():
	for x in range(1, CHUNK_SIZE - 1, 1):
		for y in range(1, CHUNK_SIZE - 1, 1):
			if chunk_array[x][y] == "FREE":
				var result = Vector3.ZERO
				result.x = (x - HALF_CHUNK_SIZE + 0.5) * scale_size_map
				result.z = (y - HALF_CHUNK_SIZE + 0.5) * scale_size_map
				result.y = 0
				return result

func portal_destroyed():
	created_portal.queue_free()
	create_chunk()

func create_navigation():
	timer_bake_wait.start()
	call_deferred("bake_navigation_mesh")
	
func _on_timer_bake_wait_timeout() -> void:
	if is_baking():
		timer_bake_wait.start()  # jeszcze nie skończone, czekaj dalej
	else:
		pass
		#print("Bake finished!")

func create_path_with_portal():
	var random_index : int
	var painter_position = Vector2i()
	var portal_placed = false

	if chunks_created_amount == 0:
		painter_position = Vector2i(1, 1)
	else:
		painter_position = Vector2i(1, last_y_list[-1])
		chunk_array[0][painter_position.y] = "FREE"

	chunk_array[painter_position.x][painter_position.y] = "FREE"

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

		chunk_array[painter_position.x][painter_position.y] = "FREE"

		# Случайное размещение портала на пути
		if !portal_placed and painter_position.x > 1 and painter_position.x < CHUNK_SIZE - 2 and randf() < 0.2:
			chunk_array[painter_position.x][painter_position.y] = "PORTAL"
			portal_position_in_array = painter_position
			portal_placed = true

	# Если портал не был размещен случайно, размещаем его в конце пути
	if !portal_placed:
		chunk_array[painter_position.x][painter_position.y] = "PORTAL"
		portal_position_in_array = painter_position

	last_y_list.append(painter_position.y)

func visualize_blocks_and_create_barriers():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y] == "BLOCK":
				created_prefab = block_prefab.instantiate()
				created_prefab.position = scale_size_map * Vector3(x - HALF_CHUNK_SIZE + (CHUNK_SIZE * chunks_created_amount) + 0.5, -0.375, y - HALF_CHUNK_SIZE + 0.5)
				created_prefab.scale *= scale_size_map
				chunk_list[-1].add_child(created_prefab)

func chunk_array_clear():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			chunk_array[x][y] = "BLOCK"
	portal_position_in_array = Vector2i.ZERO

func chunks_clearing():
	if chunks_created_amount > 2:
		for chunk in chunk_list:
			if chunk != null:
				chunk.queue_free()
				break

func create_environment():
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			if chunk_array[x][y] == "FREE" or chunk_array[x][y] == "PORTAL":
				if x + 1 <= CHUNK_SIZE - 1 and chunk_array[x + 1][y] == "BLOCK":
					create_object(corner_prefab, x, 0.0625, y, 0, 1)
				if x - 1 >= 0 and chunk_array[x - 1][y] == "BLOCK":
					create_object(corner_prefab, x, 0.0625, y, 180, 1)
				if y + 1 <= CHUNK_SIZE - 1 and chunk_array[x][y + 1] == "BLOCK":
					create_object(corner_prefab, x, 0.0625, y, -90, 1)
				if y - 1 >= 0 and chunk_array[x][y - 1] == "BLOCK":
					create_object(corner_prefab, x, 0.0625, y, 90, 1)

				if (x > 0 and y > 0 and chunk_array[x - 1][y - 1] == "BLOCK" and
					chunk_array[x - 1][y] == "FREE" and chunk_array[x][y - 1] == "FREE"):
					create_object(corner_connector_prefab, x, 0.0625, y, 0, 1)

				# Правый нижний угол
				if (x < CHUNK_SIZE - 1 and y > 0 and chunk_array[x + 1][y - 1] == "BLOCK" and
					chunk_array[x + 1][y] == "FREE" and chunk_array[x][y - 1] == "FREE"):
					create_object(corner_connector_prefab, x, 0.0625, y, 90, 1)

				# Левый верхний угол
				if (x > 0 and y < CHUNK_SIZE - 1 and chunk_array[x - 1][y + 1] == "BLOCK" and
					chunk_array[x - 1][y] == "FREE" and chunk_array[x][y + 1] == "FREE"):
					create_object(corner_connector_prefab, x, 0.0625, y, -90, 1)

				# Правый верхний угол
				if (x < CHUNK_SIZE - 1 and y < CHUNK_SIZE - 1 and chunk_array[x + 1][y + 1] == "BLOCK" and
					chunk_array[x + 1][y] == "FREE" and chunk_array[x][y + 1] == "FREE"):
					create_object(corner_connector_prefab, x, 0.0625, y, 0, 1)

				create_object(grass_plane_prefab, x, 0, y, 0, 1)

			# Размещение камней и деревьев только на клетках "BLOCK"
			if chunk_array[x][y] == "BLOCK":
				for a in 3:
					create_object(tree10_prefab, randf_range(x + 0.5, x - 0.5), 0, randf_range(y + 0.5, y - 0.5), randi_range(0, 360), randf_range(0.05, 0.15))
				create_object(bush08_prefab, randf_range(x + 0.5, x - 0.5), 0, randf_range(y + 0.5, y - 0.5), randi_range(0, 360), randf_range(0.02, 0.05))
				create_object(stone_prefab, randf_range(x + 0.5, x - 0.5), 0, randf_range(y + 0.5, y - 0.5), randi_range(0, 360), randf_range(0.4, 0.5))

			# Размещение камней на свободных клетках (не портал)
			if chunk_array[x][y] == "FREE":
				create_object(stone_prefab, randf_range(x + 0.5, x - 0.5), 0, randf_range(y + 0.5, y - 0.5), randi_range(0, 360), randf_range(0.2, 0.3))
			for a in 3:
				create_object(dead_tree_prefab, randf_range(x + 0.5, x - 0.5), -0.05, randf_range(y + 0.5, y - 0.5), randi_range(0, 360), randf_range(0.05, 0.075))

func create_object(prefab_variable, x, y, z, rotation_y, scale_multiply):
	created_prefab = prefab_variable.instantiate()
	created_prefab.position.x = scale_size_map * (x - HALF_CHUNK_SIZE + (CHUNK_SIZE * chunks_created_amount) + 0.5)
	created_prefab.position.y = scale_size_map * y
	created_prefab.position.z = scale_size_map * (z - HALF_CHUNK_SIZE + 0.5)
	created_prefab.rotation_degrees.y = rotation_y
	created_prefab.scale *= scale_size_map * scale_multiply
	chunk_list[-1].add_child(created_prefab)
