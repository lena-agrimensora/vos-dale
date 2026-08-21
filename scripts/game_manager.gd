class_name GameManager
extends Node


@export_category("References")

@export var board: Board
@export var game_controller: GameController
@export var piece_scene: PackedScene
@export var camera: Camera3D

var selected_slot: int = 1

var preview_piece: Piece = null

func _ready() -> void:

	if board == null:push_error("[GameManager] - Board no está asignado.")

	if game_controller == null:
		push_error("[GameManager] - GameController no está asignado.")

	if piece_scene == null:
		push_error("[GameManager] - Piece Scene no está asignada.")

	if camera == null:
		push_error("[GameManager] - Camera no está asignada.")

	game_controller.current_player_changed.connect(_on_player_changed)

	create_preview()

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey:

		if event.pressed and not event.echo:
			match event.keycode:
				KEY_1:
					select_slot(1)

				KEY_2:
					select_slot(2)

				KEY_3:
					select_slot(3)

				KEY_4:
					select_slot(4)

				KEY_5:
					select_slot(5)

				KEY_6:
					select_slot(6)

				KEY_7:
					select_slot(7)

				KEY_8:
					select_slot(8)

				KEY_9:
					select_slot(9)


	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				place_selected_piece()


func select_slot(slot: int) -> void:

	selected_slot = slot

	print("[Game Manager] - Seleccionaste el slot: ",selected_slot)
	create_preview()

func create_preview() -> void:

	remove_preview()

	if piece_scene == null:
		return

	preview_piece = piece_scene.instantiate()

	add_child(preview_piece)

	preview_piece.visible = false

	update_preview_visual()


func update_preview_visual() -> void:

	if preview_piece == null:
		return

	preview_piece.set_player(game_controller.current_player)

	if game_controller.current_phase == (GameController.GAME_PHASE.CORE_PLACEMENT):

		preview_piece.set_piece_type(Piece.PIECE_TYPE.CORE)

	else:
		preview_piece.set_piece_type(Piece.PIECE_TYPE.NORMAL)

func _on_player_changed(_player: GameController.PLAYER) -> void:

	update_preview_visual()



func _process(_delta: float) -> void:

	if preview_piece == null:
		return


	update_preview_position()

func update_preview_position() -> void:

	var mouse_position: Vector2 = (get_viewport().get_mouse_position())

	var ray_origin: Vector3 = (camera.project_ray_origin(mouse_position))

	var ray_direction: Vector3 = (camera.project_ray_normal(mouse_position))


	if abs(ray_direction.y) < 0.001:
		preview_piece.visible = false
		return

	var distance: float = (-ray_origin.y / ray_direction.y)


	if distance < 0.0:
		preview_piece.visible = false
		return


	var world_position: Vector3 = (ray_origin + ray_direction * distance)


	var grid_position: Vector2i = (board.world_to_grid(world_position))


	var cell: Cell = (board.get_cell(grid_position))

	if cell == null:

		preview_piece.visible = false
		return


	if not game_controller.can_place_piece(cell):
		preview_piece.visible = false
		return


	preview_piece.visible = true

	preview_piece.global_position = (cell.global_position+ Vector3.UP * 0.35)

func place_selected_piece() -> void:

	if preview_piece == null:
		return


	if not preview_piece.visible:
		return


	var mouse_position: Vector2 = (get_viewport().get_mouse_position())


	var ray_origin: Vector3 = (camera.project_ray_origin(mouse_position)
	)


	var ray_direction: Vector3 = (camera.project_ray_normal(mouse_position))


	if abs(ray_direction.y) < 0.001:
		return


	var distance: float = (-ray_origin.y / ray_direction.y)


	if distance < 0.0:
		return


	var world_position: Vector3 = (ray_origin + ray_direction * distance)


	var grid_position: Vector2i = (board.world_to_grid(world_position))


	var cell: Cell = (board.get_cell(grid_position))


	if cell == null:
		return


	var placed: bool = (game_controller.try_place_piece(cell,selected_slot))


	if not placed:
		return


	print("[GameManager] - Pieza colocada en ",cell.grid_position)



func remove_preview() -> void:

	if preview_piece != null:
		preview_piece.queue_free()
		preview_piece = null