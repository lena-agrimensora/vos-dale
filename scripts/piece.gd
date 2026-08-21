class_name Piece
extends Node3D


enum PIECE_TYPE {
	NORMAL,
	CORE
}


@export var current_type: PIECE_TYPE = PIECE_TYPE.NORMAL

var player_id: int = -1


func set_player(value: int) -> void:
	player_id = value

	match player_id:
		0:
			set_piece_color(Color.WHITE)

		1:
			set_piece_color(Color.BLACK)


func set_piece_type(type: PIECE_TYPE) -> void:
	current_type = type

	update_type_visual()


func update_type_visual() -> void:
	if not has_node("CoreMarker"):
		return

	var core_marker: Node3D = $CoreMarker

	core_marker.visible = current_type == PIECE_TYPE.CORE


func set_piece_color(color: Color) -> void:
	if not has_node("MeshInstance3D"):
		push_error("[Piece] - No se encontró MeshInstance3D")
		return

	var mesh_instance: MeshInstance3D = $MeshInstance3D

	if mesh_instance.mesh == null:
		push_error("[Piece] - MeshInstance3D no tiene un Mesh asignado")
		return

	var material := StandardMaterial3D.new()

	material.albedo_color = color

	mesh_instance.material_override = material