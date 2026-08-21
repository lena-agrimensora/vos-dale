class_name Cell
extends Area3D


signal clicked(cell: Cell)


var grid_position: Vector2i
var pieces: Array[Piece] = []


func is_occupied() -> bool:
	return not pieces.is_empty()


func get_tower_height() -> int:
	return pieces.size()


func add_piece(piece: Piece) -> void:
	if piece == null:
		push_error("[Cell] - Intento de agregar una Piece nula.")
		return

	pieces.append(piece)


func can_stack_piece(piece: Piece) -> bool:
	if pieces.is_empty():
		return true

	return pieces[0].player_id == piece.player_id


func get_top_piece() -> Piece:
	if pieces.is_empty():
		return null

	return pieces.back()


func _on_input_event(camera: Node,event: InputEvent,event_position: Vector3,normal: Vector3,shape_idx: int) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[Cell] - Pressed left mouse button ")
			clicked.emit(self)
