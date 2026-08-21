class_name GameManager
extends Node


@export_category("References")

@export var game_controller: GameController
@export var board: Board
@export var piece_scene: PackedScene
@export var camera: Camera3D


@export_category("Preview")

@export var preview_height: float = 0.2


var selected_slot: int = -1
var preview_piece: Piece


func _ready() -> void:
	create_preview()
	board.cell_clicked.connect(_on_board_cell_clicked)


func _process(_delta: float) -> void:
	update_preview_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			handle_number_key(event)


func handle_number_key(event: InputEventKey) -> void:
	var key_number := get_number_from_key(event.keycode)

	if key_number == -1:
		return

	select_slot(key_number)


func get_number_from_key(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 1
		KEY_2:
			return 2
		KEY_3:
			return 3
		KEY_4:
			return 4
		KEY_5:
			return 5
		KEY_6:
			return 6
		KEY_7:
			return 7
		KEY_8:
			return 8
		KEY_9:
			return 9

	return -1


func select_slot(slot: int) -> void:
	selected_slot = slot

	print("[Game Manager] - Seleccionaste el slot: ", selected_slot)

	update_preview()

func create_preview() -> void:
	preview_piece = piece_scene.instantiate()

	add_child(preview_piece)

	preview_piece.visible = false


func update_preview() -> void:
	if not is_instance_valid(preview_piece):
		return

	preview_piece.set_player(game_controller.current_player)

	
	if game_controller.current_phase == GameController.GAME_PHASE.CORE_PLACEMENT:
		preview_piece.set_piece_type(Piece.PIECE_TYPE.CORE)
	else:
		preview_piece.set_piece_type(Piece.PIECE_TYPE.NORMAL)

	preview_piece.visible = true


func update_preview_position() -> void:
	if not is_instance_valid(preview_piece):
		return

	if selected_slot == -1:
		preview_piece.visible = false
		return

	var mouse_position := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)

	
	var plane := Plane(Vector3.UP, 0.0)

	var intersection = plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if intersection == null:
		preview_piece.visible = false
		return

	var world_position: Vector3 = intersection

	var grid_position := board.world_to_grid(world_position)

	
	if not is_grid_position_valid(grid_position):
		preview_piece.visible = false
		return

	var cell := board.get_cell(grid_position)

	if cell == null:
		preview_piece.visible = false
		return

	
	preview_piece.global_position = (
		cell.global_position
		+ Vector3.UP * preview_height
	)

	preview_piece.visible = true


func is_grid_position_valid(grid_position: Vector2i) -> bool:
	return (
		grid_position.x >= 0
		and grid_position.x < board.columns
		and grid_position.y >= 0
		and grid_position.y < board.rows
	)


func _on_board_cell_clicked(cell: Cell) -> void:
	if selected_slot == -1:
		return

	print(
		"[Game Manager] - Click en ",
		cell.grid_position,
		" usando slot ",
		selected_slot
	)

	var success = game_controller.try_place_piece(
		cell,
		selected_slot
	)

	if success:
		selected_slot = -1
		preview_piece.visible = false