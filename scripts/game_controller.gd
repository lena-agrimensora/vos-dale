class_name GameController
extends Node

# *** Enums ***
enum PLAYER {
	ONE,
	TWO
}


enum GAME_PHASE {
	CORE_PLACEMENT,
	NORMAL_PLAY,
	EXPANDED_PLAY
}


# *** Signals ***

signal player_stats_changed(player: PLAYER,piece_count: int,multiplier: float,score: float)
signal current_player_changed(player: PLAYER)
signal phase_changed(phase: GAME_PHASE)
signal expansion_turns_changed(turns: int)


# *** References ***

@export_category("References")

@export var board: Board
@export var piece_scene: PackedScene
@export var game_ui: GameUI


# *** Game Balance ***

@export_category("Game Balance")

@export var core_pieces_per_player : int = 3
@export var turns_until_expansion  : int = 10
@export var player_time_seconds    : float = 300.0


@export_category("Phase 3 Variables")

@export var phase_3_board_size      : int = 21
@export var phase_3_pieces_per_turn : int = 2


# *** Game State ***

var current_player        : PLAYER = PLAYER.ONE
var current_phase         : GAME_PHASE = GAME_PHASE.CORE_PLACEMENT
var core_placements       : int = 0
var expansion_turns_left  : int = 0
var pieces_left_this_turn : int = 1

#*** Player Time ***

var player_time_left: Dictionary = {
	PLAYER.ONE: 0.0,
	PLAYER.TWO: 0.0
}

# *** Chain Mult ***
var chain_multipliers: Dictionary = {
	PLAYER.ONE: 1.0,
	PLAYER.TWO: 1.0
}

var max_core_placements: int:
	get:
		return core_pieces_per_player * 2

func _ready() -> void:

	if board == null:
		push_error("[GameController] - Board no está asignado.")
		return

	if piece_scene == null:
		push_error("[GameController] - Piece Scene no está asignada.")
		return

	if game_ui == null:
		push_error("[GameController] - GameUI no está asignado.")
		return

	player_time_left[PLAYER.ONE] = player_time_seconds
	player_time_left[PLAYER.TWO] = player_time_seconds

	expansion_turns_left = turns_until_expansion

	pieces_left_this_turn = 1

	board.cell_clicked.connect(_on_board_cell_clicked)

	game_ui.update_player_stats(
		PLAYER.ONE,
		get_player_piece_count(PLAYER.ONE),
		get_player_multiplier(PLAYER.ONE),
		get_player_score(PLAYER.ONE)
	)

	game_ui.update_player_stats(
		PLAYER.TWO,
		get_player_piece_count(PLAYER.TWO),
		get_player_multiplier(PLAYER.TWO),
		get_player_score(PLAYER.TWO)
	)

	game_ui.update_current_player(current_player)

	game_ui.update_phase("FASE 1 - CORE")

	game_ui.update_expansion_turns(expansion_turns_left)

	game_ui.update_timer(PLAYER.ONE,player_time_left[PLAYER.ONE])

	game_ui.update_timer(PLAYER.TWO,player_time_left[PLAYER.TWO])

	game_ui.update_pieces_remaining(pieces_left_this_turn)


	print("[GameController] - Comienza la partida")
	print("[GameController] - FASE 1: colocación de CORE")
	print("[GameController] - Turno Player 1")



func _process(delta: float) -> void:

	player_time_left[current_player] -= delta

	if player_time_left[current_player] < 0.0:
		player_time_left[current_player] = 0.0


	if game_ui != null:
		game_ui.update_timer(current_player,player_time_left[current_player])


	if player_time_left[current_player] <= 0.0:
		on_player_time_out()


func on_player_time_out() -> void:

	print("[GameController] - Player ",	current_player + 1," se quedó sin tiempo.")
	set_process(false)

func _on_board_cell_clicked(cell: Cell) -> void:

	print("[GameController] - Cell recibida: ",cell.grid_position)


func can_place_piece(cell: Cell) -> bool:

	if cell == null:
		return false

	if not board.is_cell_empty(cell):
		return false

	if current_phase == GAME_PHASE.CORE_PLACEMENT:
		return true

	return board.has_adjacent_piece_of_player(cell,current_player)


func try_place_piece(cell: Cell,slot: int) -> bool:

	if cell == null:
		return false


	if not can_place_piece(cell):

		print("[GameController] - No se puede colocar en ",cell.grid_position)

		return false

	var piece: Piece = create_piece()

	if piece == null:

		push_error("[GameController] - No se pudo crear la pieza.")

		return false

	var placed: bool = board.place_piece(cell,piece)

	if not placed:

		piece.queue_free()
		print("[GameController] - Board rechazó la pieza.")
		return false

	print("[GameController] - Player ",current_player + 1," colocó ",get_piece_type_name(piece)," en ",cell.grid_position)

	var captured_count: int = resolve_capture_chain(cell)

	if captured_count > 0:

		print("[GameController] - Cadena de captura: ",captured_count," pieza(s)")

	apply_chain_bonus(current_player,captured_count)
	update_all_player_stats()

	pieces_left_this_turn -= 1

	if game_ui != null:
		game_ui.update_pieces_remaining(
			pieces_left_this_turn
		)

	if current_phase == GAME_PHASE.CORE_PLACEMENT:

		core_placements += 1

		print("[GameController] - CORE colocadas: ",core_placements,"/",max_core_placements)

		if core_placements >= max_core_placements:

			finish_core_phase()
			pieces_left_this_turn = 0

	if pieces_left_this_turn <= 0:

		finish_turn()

	else:

		print("[GameController] - Player ",current_player + 1," todavía puede colocar ",pieces_left_this_turn," ficha(s)"
		)


	return true


func finish_turn() -> void:


	if current_phase == GAME_PHASE.NORMAL_PLAY:

		expansion_turns_left -= 1

		if expansion_turns_left < 0:
			expansion_turns_left = 0


		if game_ui != null:

			game_ui.update_expansion_turns(expansion_turns_left)


		expansion_turns_changed.emit(expansion_turns_left)


		print("[GameController] - Expansión en ",expansion_turns_left," turnos")

		if expansion_turns_left <= 0:

			finish_phase_3_expansion()
			switch_player()
			zoom_for_phase_3()
			return

	switch_player()


func create_piece() -> Piece:

	var piece: Piece = piece_scene.instantiate()

	piece.set_player(current_player)

	if current_phase == GAME_PHASE.CORE_PLACEMENT:

		piece.set_piece_type(Piece.PIECE_TYPE.CORE)

	else:

		piece.set_piece_type(Piece.PIECE_TYPE.NORMAL)


	return piece



func get_piece_type_name(piece: Piece) -> String:

	match piece.current_type:

		Piece.PIECE_TYPE.NORMAL:
			return "NORMAL"

		Piece.PIECE_TYPE.CORE:
			return "CORE"

	return "UNKNOWN"


func get_player_piece_count(player: PLAYER) -> int:

	var count: int = 0


	for grid_position in board.cells:

		var cell: Cell = board.cells[
			grid_position
		]


		for piece in cell.pieces:

			if piece.player_id == player:

				count += 1


	return count


func get_player_multiplier(player: PLAYER) -> float:

	return chain_multipliers[player]


func get_player_score(player: PLAYER) -> float:

	var piece_count: int = get_player_piece_count(player)
	var multiplier: float = get_player_multiplier(player)
	return piece_count * multiplier


func update_player_stats(player: PLAYER) -> void:

	var piece_count: int = get_player_piece_count(player)

	var multiplier: float = get_player_multiplier(player)

	var score: float = piece_count * multiplier

	player_stats_changed.emit(player,piece_count,multiplier,score)


	if game_ui != null:

		game_ui.update_player_stats(player,piece_count,multiplier,score)


func update_all_player_stats() -> void:

	update_player_stats(PLAYER.ONE)
	update_player_stats(PLAYER.TWO)


func calculate_chain_bonus(captured_count: int) -> float:

	if captured_count < 2:
		return 0.0

	return 0.05 * captured_count * (captured_count - 1)


func apply_chain_bonus(player: PLAYER,captured_count: int) -> void:

	var bonus: float = calculate_chain_bonus(captured_count)

	if bonus <= 0.0:
		return


	chain_multipliers[player] += bonus


	print("[GameController] - Player ",	player + 1," realizó una cadena de ",captured_count," capturas.")
	print("[GameController] - Chain Multiplier: ",chain_multipliers[player])


func resolve_capture_chain(start_cell: Cell) -> int:

	var total_captured: int = 0
	var cells_to_check: Array[Cell] = []
	var already_captured: Array[Piece] = []


	cells_to_check.append(start_cell)


	while not cells_to_check.is_empty():

		var cell: Cell = cells_to_check.pop_front()


		if cell == null:
			continue


		var captured_pieces: Array[Piece] = (board.get_captured_pieces_around(cell)
		)


		for captured_piece in captured_pieces:

			if captured_piece == null:
				continue


			if already_captured.has(captured_piece):continue


			if captured_piece.player_id == current_player:continue


			if captured_piece.current_type == (Piece.PIECE_TYPE.CORE):continue


			already_captured.append(captured_piece)

			capture_piece(captured_piece)

			total_captured += 1


			var captured_cell: Cell = find_piece_cell(captured_piece)


			if captured_cell == null: continue


			for direction in board.DIRECTIONS:

				var neighbor: Cell = (
					board.get_neighbor_cell(
						captured_cell,
						direction
					)
				)


				if neighbor == null:continue


				if not cells_to_check.has(neighbor):

					cells_to_check.append(neighbor)


	return total_captured


func find_piece_cell(piece: Piece) -> Cell:

	if piece == null:
		return null


	for grid_position in board.cells:

		var cell: Cell = board.cells[grid_position]


		if cell.pieces.has(piece):
			return cell

	return null



func capture_piece(piece: Piece) -> void:

	if piece == null:
		return

	if piece.current_type == (Piece.PIECE_TYPE.CORE):
		return


	var old_player: int = piece.player_id

	piece.set_player(current_player)


	print("[GameController] - Player ",current_player + 1," capturó una pieza de Player ",old_player + 1)



func finish_core_phase() -> void:

	#TODO: tomar dimensiones via @export
	board.expand_to(13,13)


	current_phase = GAME_PHASE.NORMAL_PLAY


	expansion_turns_left = turns_until_expansion

	pieces_left_this_turn = 1


	phase_changed.emit(current_phase)

	expansion_turns_changed.emit(expansion_turns_left)


	if game_ui != null:
		game_ui.update_phase("FASE 2 - NORMAL")
		game_ui.update_expansion_turns(expansion_turns_left)


func finish_phase_3_expansion() -> void:

	board.expand_to(phase_3_board_size,phase_3_board_size)

	current_phase = GAME_PHASE.EXPANDED_PLAY
	pieces_left_this_turn = phase_3_pieces_per_turn

	phase_changed.emit(current_phase)


	if game_ui != null:

		game_ui.update_phase("FASE 3 - EXPANSION")
		game_ui.update_expansion_turns(0)


func switch_player() -> void:

	if current_player == PLAYER.ONE:
		current_player = PLAYER.TWO
	else:
		current_player = PLAYER.ONE



	if current_phase == GAME_PHASE.EXPANDED_PLAY:
		pieces_left_this_turn = (phase_3_pieces_per_turn)

	else:
		pieces_left_this_turn = 1

	if game_ui != null:
		game_ui.update_pieces_remaining(pieces_left_this_turn)

	print("[GameController] - Turno Player ",current_player + 1)

	print("[GameController] - Puede colocar ",pieces_left_this_turn," ficha(s)")

	current_player_changed.emit(current_player)


	if game_ui != null:
		game_ui.update_current_player(current_player)


func zoom_for_phase_3() -> void:
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var tween := create_tween()

	tween.tween_property(camera,"position:y",camera.position.y * 1.10,0.8)
