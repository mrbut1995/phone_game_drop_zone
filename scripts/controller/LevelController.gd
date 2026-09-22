# Quản lý danh sách màn chơi.
# Mỗi màn là một SCENE kế thừa Level.tscn (res://nodes/game/level/levels/level_n.tscn)
# - thay cho việc build LevelData bằng code như trước.
class_name LevelController
extends Node

signal level_loaded(level: BaseLevel)
signal mode_selected(mode: GameState.GameMode)

# Danh sách level scene, gán trực tiếp trong game.tscn theo thứ tự màn 1 -> n
@export var level_scenes: Array[PackedScene] = []

# Scene dự phòng khi chưa gán level_scenes
const FALLBACK_LEVEL_SCENE: PackedScene = preload("res://nodes/game/level/Level.tscn")

var current_level_index: int = 0
var current_mode: GameState.GameMode = GameState.GameMode.CAMPAIGN

func get_level_count() -> int:
	return level_scenes.size()

func get_current_level_number() -> int:
	return current_level_index + 1

# Instantiate Level scene của màn hiện tại rồi phát signal "level_loaded".
# WorldController (dựng màn + cấu hình bia) và SpawnerController (spawn obstacle theo marker)
# đều lắng nghe signal này - kết nối khai báo trong game.tscn.
func load_current_level() -> BaseLevel:
	if level_scenes.is_empty():
		push_warning("LevelController: chưa gán level_scenes trong game.tscn")
		current_level_index = 0
	else:
		current_level_index = clampi(current_level_index, 0, level_scenes.size() - 1)

	var scene: PackedScene = FALLBACK_LEVEL_SCENE if level_scenes.is_empty() else level_scenes[current_level_index]
	var level: BaseLevel = scene.instantiate() as BaseLevel
	if level == null:
		push_error("LevelController: scene màn không kế thừa BaseLevel: " + scene.resource_path)
		return null

	level_loaded.emit(level)
	return level

# Chuyển sang màn kế tiếp (chỉ đổi chỉ số, màn sẽ được load ở start_game)
func next_level() -> void:
	if level_scenes.is_empty():
		return
	current_level_index = (current_level_index + 1) % level_scenes.size()

func set_mode(mode: GameState.GameMode) -> void:
	current_mode = mode
	mode_selected.emit(mode)
