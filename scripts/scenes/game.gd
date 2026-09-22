extends BaseScene

@onready var game_logic_controller: GameLogicController = $Controllers/GameLogicController

func _ready() -> void:
	# Binding Controller và kết nối signal đều được cấu hình trong game.tscn.
	# Scene script chỉ chịu trách nhiệm khởi động vòng lặp game.
	game_logic_controller.start_game(GameState.GameMode.CAMPAIGN)
