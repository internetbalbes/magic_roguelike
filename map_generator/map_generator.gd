extends Node3D

const MAP_SIZE = 7
const MAX_CHUNKS = 2

var half_size = MAP_SIZE / 2.0	
var maps_created_amount : int = 0
var last_y : int

var map_array = []

var chunk_list: Array[Node3D] = []
var last_y_list : Array[int] = []

var created_portal : MeshInstance3D
var created_barrier : StaticBody3D

@onready var block = load("res://map/prefabs/block/block.tscn")
@onready var ground = load("res://map/prefabs/ground/ground.tscn")
@onready var portal = load("res://portal.tscn")
@onready var barrier = load("res://barrier.tscn")

func _ready() -> void:
	generate_location()

func generate_location():
	var current_chunk = Node3D.new()
	add_child(current_chunk)
	chunk_list.append(current_chunk)
	
	if chunk_list.size() > MAX_CHUNKS:
		var old_chunk = chunk_list.pop_front()
		old_chunk.queue_free()
		
		var old_y = last_y_list.pop_front()
		
		var created_block = block.instantiate()
		created_block.position = Vector3(
			half_size + (MAP_SIZE * (maps_created_amount - MAX_CHUNKS)) + 0.5,
			0.5,
			old_y - half_size + 0.5
		)
		current_chunk.add_child(created_block)
		
	var painter_position = Vector2i()
	var created_block : StaticBody3D
	
	map_array.clear()
	
	var created_ground = ground.instantiate()
	created_ground.scale *= MAP_SIZE
	created_ground.position.x = (MAP_SIZE)*maps_created_amount
	current_chunk.add_child(created_ground)
	$pivot.position = created_ground.position
	
	map_array_expansion()
			
	if maps_created_amount == 0:
		painter_position = Vector2i(1,1)
		map_array[painter_position.x][painter_position.y] = 1
	else:
		painter_position = Vector2i(1,last_y)
		map_array[painter_position.x][painter_position.y] = 1
		map_array[0][painter_position.y] = 1
	
	var random_index : int
	while painter_position.x != MAP_SIZE - 1:
		random_index = randi_range(0,4)
		match random_index:
			0:painter_position.x += 1
			1:
				if painter_position.y != MAP_SIZE - 2:
					painter_position.y += 1
			2:
				if painter_position.y != 1:
					painter_position.y -= 1
			3:
				if painter_position.x != 1:
					painter_position.x -= 1
					
		map_array[painter_position.x][painter_position.y] = 1
	
	var random_position_index : Vector2i
	while true:
		random_position_index = Vector2i(randi_range(0,MAP_SIZE - 2),randi_range(0,MAP_SIZE - 2))
		if map_array[random_position_index.x][random_position_index.y] == 1:
			map_array[random_position_index.x][random_position_index.y] = 2
			break
	
	created_barrier = barrier.instantiate()
	created_barrier.position = Vector3(painter_position.x - half_size + (MAP_SIZE * maps_created_amount) + 0.5,0.5,painter_position.y - half_size + 0.5)
	current_chunk.add_child(created_barrier)
			
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			if map_array[x][y] == 0:
				created_block = block.instantiate()
				created_block.position = Vector3(x - half_size + (MAP_SIZE * maps_created_amount) + 0.5,0.5,y - half_size + 0.5)
				current_chunk.add_child(created_block)
			if map_array[x][y] == 2:
				created_portal = portal.instantiate()
				created_portal.position = Vector3(x - half_size + (MAP_SIZE * maps_created_amount) + 0.5,0.5,y - half_size + 0.5)
				current_chunk.add_child(created_portal)
	
	
	last_y = painter_position.y
	maps_created_amount += 1
	last_y_list.append(last_y)
	
func map_array_expansion():
	for i in range(MAP_SIZE):
		map_array.append([])
		for j in range(MAP_SIZE):
			map_array[i].append(0)	

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		portal_destroyed()

func portal_destroyed():
		created_portal.queue_free()
		created_barrier.queue_free()
		generate_location()
