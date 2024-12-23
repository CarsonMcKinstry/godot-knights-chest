class_name Selector extends Area2D

signal turn_finished

@export var sprite: AnimatedSprite2D
@export var movement_controller: GridController
@export var chess_board: ChessBoard
@export var player_party: PartyController
@export var opponent_party: PartyController

enum SelectorState {
	PieceSelect, # Choosing a piece to move
	PieceSelected, # Piece has been choosen
	TargetSelect,
	Idle, # Waiting for the piece to finish moving
}

var state: SelectorState = SelectorState.Idle

var hovered_piece: Piece = null
var selected_piece: Piece = null

func _physics_process(_delta: float) -> void:
	
	if state == SelectorState.Idle:
		self.hide()
	else:
		self.show()
	#
	match state:
		SelectorState.PieceSelect:
			sprite.play("default")
			handle_move()
			handle_select()
		SelectorState.PieceSelected:
			sprite.play("hovering_piece")
			handle_move()
			handle_target_select()
			
func handle_move() -> void:
	var direction = movement_controller.get_movement_direction()
	
	if direction != Vector2.ZERO:
		if chess_board != null:
			if !chess_board.is_direction_out_of_bounds(position, direction):
				movement_controller.move_in(direction)
				await movement_controller.finished_moving
		else:
			movement_controller.move_in(direction)
			await movement_controller.finished_moving

func handle_select() -> void:
	if Input.is_action_just_pressed("ui_select"):
		var relative_position = chess_board.get_relative_position(position)
		
		var player_piece = chess_board.get_player_piece_at(relative_position)
		
		if player_piece != null:
			player_piece.select()
			selected_piece = player_piece
			state = SelectorState.PieceSelected

func handle_target_select() -> void:
	if Input.is_action_just_pressed("ui_select"):
		var relative_position = chess_board.get_relative_position(position)
		
		if can_piece_move_there(relative_position):
			
			var target_piece = chess_board.get_piece_at(relative_position)

			if target_piece != null:
				if player_party.contains(target_piece):
					pass
				elif opponent_party.contains(target_piece):
					await attack_target(target_piece)
			else:
				await move_piece_to_position(relative_position)

	elif Input.is_action_just_pressed("ui_cancel"):
		selected_piece.deselect()
		state = SelectorState.PieceSelect
		selected_piece = null

func attack_target(target: Piece) -> void:
	selected_piece.deselect()
	state = SelectorState.Idle
	await selected_piece.attack_target(target)
	selected_piece = null
	turn_finished.emit()

func move_piece_to_position(pos: Vector2) -> void:
	selected_piece.move()
	selected_piece.deselect()
	state = SelectorState.Idle
	await selected_piece.move_to_position(pos)
	selected_piece.idle()
	selected_piece = null
	turn_finished.emit()

func can_piece_move_there(position: Vector2) -> bool:
	return selected_piece.move_calculator != null && selected_piece.move_calculator.indicator_positions.has(position)

func start_turn() -> void:
	state = SelectorState.PieceSelect


func _on_area_entered(piece: Piece) -> void:
	# use this later for UI?
	hovered_piece = piece


func _on_area_exited(piece: Piece) -> void:
	# same here?
	hovered_piece = null
