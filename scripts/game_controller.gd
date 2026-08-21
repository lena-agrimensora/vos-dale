class_name GameController
extends Node


enum PLAYER {
	ONE,
	TWO
}


enum GAME_PHASE {
	CORE_PLACEMENT,
	NORMAL_PLAY
}


@export_category("References")

@export var board: Board
@export var piece_scene: PackedScene

var current_player: PLAYER = PLAYER.ONE

var current_phase: GAME_PHASE = (
	GAME_PHASE.CORE_PLACEMENT
)


var core_placements: int = 0

const MAX_CORE_PLACEMENTS: int = 6


var scores := {
	PLAYER.ONE: 0,
	PLAYER.TWO: 0
}



func _ready() -> void:

	print("[GameController] - Comienza la partida")

	print(
		"[GameController] - FASE 1: colocación de CORE"
	)

	print(
		"[GameController] - Turno Player 1"
	)

func can_place_piece(cell: Cell) -> bool:

	if cell == null:
		return false

	
	if not board.is_cell_empty(cell):
		return false


	if current_phase == GAME_PHASE.CORE_PLACEMENT:
		return true

	return board.has_adjacent_piece_of_player(
		cell,
		current_player
	)

func try_place_piece(
	cell: Cell,
	slot: int
) -> bool:

	if not can_place_piece(cell):

		print(
			"[GameController] - No se puede colocar en ",
			cell.grid_position
		)

		return false

	var piece: Piece = create_piece()

	var placed := board.place_piece(
		cell,
		piece
	)

	if not placed:

		piece.queue_free()

		return false

	print(
		"[GameController] - Player ",
		current_player + 1,
		" colocó ",
		get_piece_type_name(piece),
		" en ",
		cell.grid_position
	)


	var captured_pieces := (
		board.get_captured_pieces_around(cell)
	)

	for captured_piece in captured_pieces:
		capture_piece(captured_piece)


	if current_phase == GAME_PHASE.CORE_PLACEMENT:

		core_placements += 1

		print(
			"[GameController] - CORE colocadas: ",
			core_placements,
			"/",
			MAX_CORE_PLACEMENTS
		)

		if core_placements >= MAX_CORE_PLACEMENTS:
			finish_core_phase()


	switch_player()

	return true


func create_piece() -> Piece:

	var piece: Piece = (
		piece_scene.instantiate()
	)

	
	piece.set_player(current_player)

	
	if current_phase == GAME_PHASE.CORE_PLACEMENT:

		piece.set_piece_type(
			Piece.PIECE_TYPE.CORE
		)

	else:

		piece.set_piece_type(
			Piece.PIECE_TYPE.NORMAL
		)

	return piece


func get_piece_type_name(
	piece: Piece
) -> String:

	match piece.current_type:

		Piece.PIECE_TYPE.NORMAL:
			return "NORMAL"

		Piece.PIECE_TYPE.CORE:
			return "CORE"

	return "UNKNOWN"


func capture_piece(piece: Piece) -> void:

	var old_player := piece.player_id

	
	piece.set_player(current_player)

	
	scores[current_player] += 1

	print(
		"[GameController] - Player ",
		current_player + 1,
		" capturó una pieza de Player ",
		old_player + 1,
		" | Score: ",
		scores[current_player]
	)


func finish_core_phase() -> void:

	print(
		"[GameController] - ==========================="
	)

	print(
		"[GameController] - FASE 1 TERMINADA"
	)

	print(
		"[GameController] - EXPANDIENDO TABLERO"
	)

	print(
		"[GameController] - ==========================="
	)

	board.expand_to(13, 13)

	current_phase = GAME_PHASE.NORMAL_PLAY

	print(
		"[GameController] - ==========================="
	)

	print(
		"[GameController] - FASE 2 INICIADA"
	)

	print(
		"[GameController] - Las piezas deben expandirse ",
		"desde territorio propio."
	)

	print(
		"[GameController] - ==========================="
	)


func switch_player() -> void:

	if current_player == PLAYER.ONE:
		current_player = PLAYER.TWO
	else:
		current_player = PLAYER.ONE

	print(
		"[GameController] - Turno Player ",
		current_player + 1
	)