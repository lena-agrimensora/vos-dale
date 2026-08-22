class_name Board
extends Node3D


@export_category("Board Settings")

@export var columns   : int = 13
@export var rows      : int = 1
@export var cell_size : float = 1.0


@export_category("Scenes")

@export var cell_scene: PackedScene


signal cell_clicked(cell: Cell)


var cells: Dictionary = {}


const DIRECTIONS := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),

	Vector2i(-1, 0),
	Vector2i(1, 0),

	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]


const CAPTURE_PAIRS := [
	[
		Vector2i(0, -1),
		Vector2i(0, 1)
	],

	[
		Vector2i(-1, 0),
		Vector2i(1, 0)
	],

	[
		Vector2i(-1, -1),
		Vector2i(1, 1)
	],

	[
		Vector2i(1, -1),
		Vector2i(-1, 1)
	]
]


func _ready() -> void:
	create_board()


func create_board() -> void:
	for y in range(rows):
		for x in range(columns):
			create_cell(x, y)


func create_cell(x: int, y: int) -> void:
	var cell: Cell = cell_scene.instantiate()

	add_child(cell)

	var offset_x := (columns - 1) * 0.5
	var offset_y := (rows - 1) * 0.5

	cell.position = Vector3((x - offset_x) * cell_size,	0.0,(y - offset_y) * cell_size)

	cell.grid_position = Vector2i(x, y)

	cells[cell.grid_position] = cell

	cell.clicked.connect(_on_cell_clicked)



func get_cell(grid_position: Vector2i) -> Cell:
	return cells.get(grid_position)


func world_to_grid(world_position: Vector3) -> Vector2i:
	var offset_x := (columns - 1) * 0.5
	var offset_y := (rows - 1) * 0.5

	var grid_x := roundi(world_position.x / cell_size + offset_x)

	var grid_y := roundi(world_position.z / cell_size + offset_y)

	return Vector2i(grid_x, grid_y)



func expand_to(new_columns: int, new_rows: int) -> void:

	var old_cells := cells

	var old_columns := columns
	var old_rows := rows

	columns = new_columns
	rows = new_rows

	cells = {}

	var offset_x: int = (new_columns - old_columns) / 2
	var offset_y: int = (new_rows - old_rows) / 2

	for y in range(new_rows):

		for x in range(new_columns):

			create_cell(x, y)


	for old_position in old_cells:

		var old_cell: Cell = old_cells[old_position]

		var new_position := Vector2i(
			old_position.x + offset_x,
			old_position.y + offset_y
		)

		var new_cell: Cell = cells[new_position]

		for piece in old_cell.pieces:

			new_cell.pieces.append(piece)


			piece.global_position = (
				new_cell.global_position
				+ Vector3.UP * 0.2
			)

		old_cell.queue_free()


	for grid_position in cells:

		update_piece_position(
			cells[grid_position]
		)


func update_all_piece_positions() -> void:

	for grid_position in cells:

		var cell: Cell = cells[grid_position]

		if cell.pieces.is_empty():
			continue

		update_piece_position(cell)


func place_piece(cell: Cell, piece: Piece) -> bool:

	if cell == null:
		return false

	if piece == null:
		return false

	if not cell.can_stack_piece(piece):
		return false

	cell.add_piece(piece)

	add_child(piece)

	update_piece_position(cell)

	return true


func update_piece_position(cell: Cell) -> void:

	for i in cell.pieces.size():

		var piece: Piece = cell.pieces[i]

		piece.global_position = (cell.global_position+ Vector3.UP * (0.2 + i * 0.25))


func get_neighbor_cell(cell: Cell,direction: Vector2i) -> Cell:

	var target_position := (cell.grid_position + direction)

	return get_cell(target_position)


func has_adjacent_piece_of_player(cell: Cell,player_id: int) -> bool:

	for direction in DIRECTIONS:

		var neighbor := get_neighbor_cell(cell,direction)

		if neighbor == null:
			continue

		if neighbor.pieces.is_empty():
			continue

		var piece: Piece = neighbor.pieces.back()

		if piece.player_id == player_id:
			return true

	return false


func is_cell_empty(cell: Cell) -> bool:
	return cell.pieces.is_empty()


func is_piece_captured(cell: Cell,piece: Piece) -> bool:

	if piece.current_type == Piece.PIECE_TYPE.CORE:
		return false

	var enemy_id := 1 - piece.player_id

	for pair in CAPTURE_PAIRS:

		var first_cell := get_neighbor_cell(
			cell,
			pair[0]
		)

		var second_cell := get_neighbor_cell(
			cell,
			pair[1]
		)

		if first_cell == null or second_cell == null:
			continue

		if first_cell.pieces.is_empty():
			continue

		if second_cell.pieces.is_empty():
			continue

		var first_piece: Piece = first_cell.pieces.back()
		var second_piece: Piece = second_cell.pieces.back()

		if (
			first_piece.player_id == enemy_id
			and second_piece.player_id == enemy_id
		):
			return true

	return false


func get_captured_pieces_around(cell: Cell) -> Array[Piece]:

	var captured: Array[Piece] = []

	for direction in DIRECTIONS:

		var neighbor := get_neighbor_cell(
			cell,
			direction
		)

		if neighbor == null:
			continue

		if neighbor.pieces.is_empty():
			continue

		var piece: Piece = neighbor.pieces.back()

		if piece.current_type == Piece.PIECE_TYPE.CORE:
			continue

		if is_piece_captured(neighbor, piece):

			if not captured.has(piece):
				captured.append(piece)

	return captured

func _on_cell_clicked(cell: Cell) -> void:

	print(
		"[Board] - Recibí signal de: ",
		cell.grid_position
	)

	cell_clicked.emit(cell)

func reposition_cells() -> void:

	var offset_x := (columns - 1) * 0.5
	var offset_y := (rows - 1) * 0.5

	for grid_position in cells:

		var cell: Cell = cells[grid_position]

		cell.position = Vector3(
			(grid_position.x - offset_x) * cell_size,
			0.0,
			(grid_position.y - offset_y) * cell_size
		)

func get_corner_positions() -> Array[Vector2i]:
	var max_x := columns - 1
	var max_y := rows - 1

	return [
		Vector2i(0, 0),
		Vector2i(max_x, 0),
		Vector2i(0, max_y),
		Vector2i(max_x, max_y)
	]

func get_free_corners() -> Array[Vector2i]:
	var free_corners: Array[Vector2i] = []

	for corner in get_corner_positions():

		var cell: Cell = get_cell(corner)

		if cell == null:
			continue

		if cell.pieces.is_empty():
			free_corners.append(corner)

	return free_corners