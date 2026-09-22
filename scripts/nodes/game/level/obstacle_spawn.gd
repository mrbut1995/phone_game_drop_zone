# Marker khai báo MỘT obstacle động cho SpawnerController.
# Đặt các marker này làm con của node "SpawnObstacles" trong Level scene.
# Vị trí của marker trong editor chính là vị trí spawn obstacle tương ứng,
# nên toàn bộ "Spawn Position" của màn được cấu hình trực quan trong .tscn.
class_name ObstacleSpawn
extends Node2D

# Scene obstacle sẽ được spawn (bird.tscn, airplane.tscn, turbulence_zone.tscn...)
@export var obstacle_scene: PackedScene

# Hướng di chuyển: 1.0 = sang phải, -1.0 = sang trái
@export var direction: float = 1.0

# Tốc độ (px/s). Giá trị âm = giữ tốc độ mặc định của scene obstacle
@export var speed: float = -1.0

# Tham số riêng của từng loại obstacle. Ví dụ:
#   powerline        -> { "line_width": 300.0, "sag_amount": 22.0 }
#   crane            -> { "is_facing_right": true, "jib_length": 200.0 }
#   updraft_zone     -> { "lift_force": 480.0 }
#   turbulence_zone  -> { "multiplier": 0.45 }
#   thin_air_zone    -> { "multiplier": 1.5 }
#   fireworks        -> { "burst_y": 400.0 }
@export var extra_params: Dictionary = {}

# Gom toàn bộ cấu hình của marker thành Dictionary cho Obstacle.setup()
func build_params() -> Dictionary:
	var params: Dictionary = extra_params.duplicate()
	params["position"] = position
	params["direction"] = direction
	if speed >= 0.0:
		params["speed"] = speed
	return params
