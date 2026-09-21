class_name LevelController
extends Node

signal level_loaded(level_data: LevelData)
signal mode_selected(mode: GameState.GameMode)

var levels: Array[LevelData] = []
var current_level_index: int = 0
var current_mode: GameState.GameMode = GameState.GameMode.CAMPAIGN

func _ready() -> void:
	_init_default_levels()

func _init_default_levels() -> void:
	levels.clear()
	
	# Màn 1: Gió nhẹ, bia đứng yên
	var l1 = LevelData.new()
	l1.level_number = 1
	l1.level_name = "Màn 1: Tân Binh Tập Luyện"
	l1.total_troops = 5
	l1.target_score = 280
	l1.base_wind_min = -40.0
	l1.base_wind_max = 40.0
	l1.gust_interval = 8.0
	l1.target_moving = false
	l1.obstacle_count = 0
	levels.append(l1)
	
	# Màn 2: Gió tạt ngang, có gió giật
	var l2 = LevelData.new()
	l2.level_number = 2
	l2.level_name = "Màn 2: Gió Tạt Ngang"
	l2.total_troops = 5
	l2.target_score = 320
	l2.base_wind_min = -90.0
	l2.base_wind_max = 90.0
	l2.gust_interval = 5.5
	l2.target_moving = false
	l2.obstacle_count = 1
	levels.append(l2)
	
	# Màn 3: Bia di chuyển qua lại, chim bay cản đường
	var l3 = LevelData.new()
	l3.level_number = 3
	l3.level_name = "Màn 3: Mục Tiêu Di Động"
	l3.total_troops = 5
	l3.target_score = 350
	l3.base_wind_min = -120.0
	l3.base_wind_max = 120.0
	l3.gust_interval = 4.5
	l3.target_moving = true
	l3.target_speed = 1.4
	l3.target_move_range = 100.0
	l3.obstacle_count = 2
	levels.append(l3)

func get_current_level_data() -> LevelData:
	if levels.is_empty():
		_init_default_levels()
	return levels[current_level_index % levels.size()]

func load_level(idx: int) -> LevelData:
	current_level_index = clamp(idx, 0, levels.size() - 1)
	var l_data = get_current_level_data()
	level_loaded.emit(l_data)
	return l_data

func next_level() -> LevelData:
	current_level_index = (current_level_index + 1) % levels.size()
	return load_level(current_level_index)

func set_mode(mode: GameState.GameMode) -> void:
	current_mode = mode
	mode_selected.emit(mode)
