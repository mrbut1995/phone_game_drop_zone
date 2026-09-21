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

	# Màn 4: Đàn chim, Khinh khí cầu và Cột khí nóng
	var l4 = LevelData.new()
	l4.level_number = 4
	l4.level_name = "Màn 4: Không Phận Phức Tạp"
	l4.total_troops = 5
	l4.target_score = 360
	l4.base_wind_min = -140.0
	l4.base_wind_max = 140.0
	l4.gust_interval = 4.0
	l4.target_moving = true
	l4.target_speed = 1.6
	l4.target_move_range = 120.0
	l4.obstacle_count = 3
	levels.append(l4)

	# Màn 5: Công trình đô thị (Cần cẩu + Dây điện + Máy bay)
	var l5 = LevelData.new()
	l5.level_number = 5
	l5.level_name = "Màn 5: Vượt Chướng Ngại Đô Thị"
	l5.total_troops = 5
	l5.target_score = 380
	l5.base_wind_min = -150.0
	l5.base_wind_max = 150.0
	l5.gust_interval = 3.8
	l5.target_moving = true
	l5.target_speed = 1.8
	l5.target_move_range = 130.0
	l5.obstacle_count = 3
	levels.append(l5)

	# Màn 6: Bão gió xoáy Turbulence, Túi khí loãng và Đĩa bay UFO
	var l6 = LevelData.new()
	l6.level_number = 6
	l6.level_name = "Màn 6: Bão Xoáy & Bí Ẩn Không Gian"
	l6.total_troops = 5
	l6.target_score = 400
	l6.base_wind_min = -180.0
	l6.base_wind_max = 180.0
	l6.gust_interval = 3.2
	l6.target_moving = true
	l6.target_speed = 2.0
	l6.target_move_range = 140.0
	l6.obstacle_count = 4
	levels.append(l6)

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
