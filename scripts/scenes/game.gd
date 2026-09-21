extends BaseScene

@onready var controllers: Node = $Controllers
@onready var game_logic_controller: GameLogicController = $Controllers/GameLogicController
@onready var sfx_controller: SfxController = $Controllers/SfxController
@onready var ui_controller: UIController = $Controllers/UIController
@onready var world_controller: WorldController = $Controllers/WorldController
@onready var input_controller: InputController = $Controllers/InputController
@onready var wind_controller: WindController = $Controllers/WindController
@onready var level_controller: LevelController = $Controllers/LevelController
@onready var spawner_controller: SpawnerController = $Controllers/SpawnerController

@onready var world_node: Node2D = $World
@onready var hud_node: Control = $UI/HUD
@onready var popup_node: Control = $UI/Popup
@onready var camera_2d: Camera2D = $Camera2D

var game_state: GameState

func _ready() -> void:
	# 1. Khởi tạo Model
	game_state = GameState.new()
	
	# 2. Khởi tạo và thiết lập các Controller View
	ui_controller.setup(hud_node, popup_node)
	spawner_controller.setup(world_node)
	world_controller.setup(world_node, camera_2d, spawner_controller)
	
	# 3. Kết nối Controllers thông qua GameLogicController
	game_logic_controller.setup(
		game_state,
		input_controller,
		wind_controller,
		level_controller,
		world_controller,
		ui_controller,
		sfx_controller,
		spawner_controller
	)
	
	# 4. Bắt đầu vòng lặp game ở chế độ Campaign
	game_logic_controller.start_game(GameState.GameMode.CAMPAIGN)
