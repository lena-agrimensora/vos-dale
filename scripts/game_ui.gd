class_name GameUI
extends CanvasLayer



@onready var player_1_name: Label = ($Player1Panel/VBoxContainer/Name)
@onready var player_1_score: Label = ($Player1Panel/VBoxContainer/Score)
@onready var player_1_timer: Label = ($Player1Panel/VBoxContainer/Timer)
@onready var player_1_piece_count: Label = ($Player1Panel/VBoxContainer/PieceCount)
@onready var player_1_multiplier: Label = ($Player1Panel/VBoxContainer/ChainMultiplier)



@onready var player_2_name: Label = ($Player2Panel/VBoxContainer/Name)
@onready var player_2_score: Label = ($Player2Panel/VBoxContainer/Score)
@onready var player_2_timer: Label = ($Player2Panel/VBoxContainer/Timer)
@onready var player_2_piece_count: Label = ($Player2Panel/VBoxContainer/PieceCount)
@onready var player_2_multiplier: Label = ($Player2Panel/VBoxContainer/ChainMultiplier)


@onready var phase_label: Label = ($CenterPanel/VBoxContainer/PhaseLabel)
@onready var turn_label: Label = ($CenterPanel/VBoxContainer/TurnLabel)
@onready var expansion_label: Label = ($CenterPanel/VBoxContainer/ExpansionLabel)
@onready var pieces_remaining_label: Label = $CenterPanel/VBoxContainer/PiecesRemainingLabel


func _ready() -> void:

	player_1_name.text = "PLAYER 1 - White"
	player_2_name.text = "PLAYER 2 - Black"

	phase_label.text = "FASE 1 - Setup"
	turn_label.text = "TURNO: PLAYER 1"
	expansion_label.text = "EXPANSION EN: --"


func update_player_stats(player: GameController.PLAYER,piece_count: int,multiplier: float,score: float) -> void:

	if player == GameController.PLAYER.ONE:

		player_1_piece_count.text = ("PIECES: %d" % piece_count)
		player_1_multiplier.text = ("CHAIN: %.1fx" % multiplier)
		player_1_score.text = ("SCORE: %.1f" % score)

	else:

		player_2_piece_count.text = ("PIECES: %d" % piece_count)
		player_2_multiplier.text = ("CHAIN: %.1fx" % multiplier)
		player_2_score.text = ("SCORE: %.1f" % score)


func update_current_player(player: GameController.PLAYER) -> void:

	turn_label.text = ("TURNO: PLAYER " + str(player + 1))

func update_phase(phase_text: String) -> void:

	phase_label.text = phase_text


func update_expansion_turns(turns: int) -> void:

	expansion_label.text = ("EXPANSION: %d" % turns)

func update_pieces_remaining(amount: int) -> void:
	pieces_remaining_label.text = "Pieces remaining: " + str(amount)



func update_timer(player: GameController.PLAYER,time_left: float) -> void:

	var total_seconds: int = maxi(0,int(ceil(time_left)))

	var minutes: int = (total_seconds / 60)

	var seconds: int = (total_seconds % 60)

	var timer_text: String = ("%02d:%02d" % [minutes, seconds])

	if player == GameController.PLAYER.ONE:
		
		player_1_timer.text = timer_text

	else:

		player_2_timer.text = timer_text
