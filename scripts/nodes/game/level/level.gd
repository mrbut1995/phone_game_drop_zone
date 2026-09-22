# Lớp cơ sở cho MỌI Level scene (thay thế hoàn toàn LevelData resource trước đây).
# Mỗi màn là một SCENE kế thừa Level.tscn, nhờ vậy có thể cấu hình bằng editor:
#   - Background      (Sprite2D): hình nền riêng từng màn (đổi modulate/position)
#   - SpawnObstacles  (Node2D)  : chứa các marker ObstacleSpawn -> obstacle spawn ĐỘNG
#   - Obstacles       (Node2D)  : chứa obstacle CỐ ĐỊNH đặt sẵn (ví dụ Cần cẩu màn 5)
class_name BaseLevel
extends Node2D

@export_group("Thông tin màn")
@export var level_number: int = 1
@export var level_name: String = "Màn 1: Tân Binh Tập Luyện"

@export_group("Luật chơi")
@export var total_troops: int = 5
@export var target_score: int = 280

@export_group("Gió")
@export var base_wind_min: float = -40.0
@export var base_wind_max: float = 40.0
@export var gust_interval: float = 8.0
@export var gust_strength_min: float = 120.0
@export var gust_strength_max: float = 240.0

@export_group("Bia mục tiêu")
@export var target_moving: bool = false
@export var target_speed: float = 1.2
@export var target_move_range: float = 110.0
# Vị trí đặt bia mục tiêu (phải khớp cao độ mặt đất ground_y)
@export var target_zone_position: Vector2 = Vector2(270.0, 840.0)

# Cao độ mặt đất của màn: Troop rơi tới đây thì tiếp đất
@export var ground_y: float = 840.0

# ============================================================
# Truy cập node con (dùng get_node_or_null vì level scene thường được
# instantiate TRƯỚC khi add vào tree, @onready sẽ chưa có giá trị).
# ============================================================

func get_background() -> Sprite2D:
	return get_node_or_null("Background") as Sprite2D

func get_spawn_obstacles_container() -> Node2D:
	return get_node_or_null("SpawnObstacles") as Node2D

func get_fixed_obstacles_container() -> Node2D:
	return get_node_or_null("Obstacles") as Node2D

# Danh sách marker spawn obstacle khai báo trong node "SpawnObstacles"
func get_spawn_markers() -> Array[ObstacleSpawn]:
	var markers: Array[ObstacleSpawn] = []
	var container := get_spawn_obstacles_container()
	if container == null:
		return markers
	for child in container.get_children():
		if child is ObstacleSpawn:
			markers.append(child)
	return markers

# Interface: áp cấu hình của màn lên bia mục tiêu (WorldController gọi)
func configure_target_zone(zone: TargetZone) -> void:
	if zone == null:
		return
	zone.position = target_zone_position
	zone.configure(target_moving, target_speed, target_move_range)
