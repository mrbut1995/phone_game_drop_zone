class_name SpawnerController
extends Node

signal troop_hit_obstacle(obstacle: Obstacle)
signal obstacle_spawned(obstacle: Obstacle)
signal zone_effect_applied(zone: Obstacle, effect_name: String)

# Gán trực tiếp trong game.tscn
@export var world_node: Node2D

var active_obstacles: Array[Obstacle] = []

# Danh mục các PackedScene obstacle có sẵn trong game
const OBSTACLE_SCENES: Dictionary = {
	"bird": preload("res://nodes/game/world/obstacles/bird.tscn"),
	"airplane": preload("res://nodes/game/world/obstacles/airplane.tscn"),
	"bird_flock": preload("res://nodes/game/world/obstacles/bird_flock.tscn"),
	"balloon": preload("res://nodes/game/world/obstacles/balloon.tscn"),
	"ufo": preload("res://nodes/game/world/obstacles/ufo.tscn"),
	"rocket": preload("res://nodes/game/world/obstacles/rocket.tscn"),
	"fireworks": preload("res://nodes/game/world/obstacles/fireworks.tscn"),
	"powerline": preload("res://nodes/game/world/obstacles/powerline.tscn"),
	"crane": preload("res://nodes/game/world/obstacles/crane.tscn"),
	"updraft_zone": preload("res://nodes/game/world/obstacles/updraft_zone.tscn"),
	"thin_air_zone": preload("res://nodes/game/world/obstacles/thin_air_zone.tscn"),
	"turbulence_zone": preload("res://nodes/game/world/obstacles/turbulence_zone.tscn")
}

# Quản lý trạng thái overlap giữa Troop và từng obstacle
var _overlapping_lethal_obs: Obstacle = null

func clear_all_obstacles() -> void:
	for obs in active_obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	active_obstacles.clear()
	_overlapping_lethal_obs = null

# Tạo một Obstacle cụ thể theo key name và truyền cấu hình
func spawn_obstacle(type_key: String, params: Dictionary = {}) -> Obstacle:
	if not OBSTACLE_SCENES.has(type_key):
		push_warning("SpawnerController: Không tìm thấy loại obstacle: " + type_key)
		return null
		
	var scene: PackedScene = OBSTACLE_SCENES[type_key]
	var obs: Obstacle = scene.instantiate() as Obstacle
	if obs == null:
		return null
		
	if world_node:
		world_node.add_child(obs)
	else:
		add_child(obs)
		
	obs.setup(params)
	active_obstacles.append(obs)
	obstacle_spawned.emit(obs)
	return obs

# Khởi tạo danh sách obstacle phong phú theo level
func spawn_level_obstacles(level_data: LevelData) -> void:
	clear_all_obstacles()
	
	var count = level_data.obstacle_count
	if count <= 0:
		return
		
	var lvl = level_data.level_number
	
	# Màn 2: 1 vật thể di chuyển (Chim hoặc Khinh khí cầu)
	if lvl == 2:
		spawn_obstacle("bird", {
			"speed": 85.0,
			"direction": 1.0,
			"y_alt": 450.0
		})
		return
		
	# Màn 3: 2 vật thể (Chim + Máy bay)
	if lvl == 3:
		spawn_obstacle("bird", {
			"speed": 80.0,
			"direction": 1.0,
			"y_alt": 360.0
		})
		spawn_obstacle("airplane", {
			"speed": 135.0,
			"direction": -1.0,
			"y_alt": 540.0
		})
		return
		
	# Màn 4 trở lên: Phối hợp đa dạng các nhóm vật thể và vùng đặc biệt
	var types_pool: Array[String] = [
		"bird", "airplane", "bird_flock", "balloon", "ufo",
		"powerline", "crane", "updraft_zone", "turbulence_zone"
	]
	
	var base_y = 280.0
	var spacing_y = 480.0 / max(1, count)
	
	for i in range(count):
		var selected_type: String = types_pool[i % types_pool.size()]
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		var alt_y: float = base_y + float(i) * spacing_y
		
		var config: Dictionary = {
			"direction": dir,
			"y_alt": alt_y
		}
		
		match selected_type:
			"bird":
				config["speed"] = randf_range(70.0, 100.0)
			"airplane":
				config["speed"] = randf_range(130.0, 160.0)
			"bird_flock":
				config["speed"] = randf_range(80.0, 110.0)
			"balloon":
				config["speed"] = randf_range(35.0, 50.0)
			"ufo":
				config["speed"] = randf_range(100.0, 130.0)
			"powerline":
				config["position"] = Vector2(270.0, alt_y)
				config["line_width"] = 380.0
			"crane":
				config["position"] = Vector2(40.0 if dir > 0 else 500.0, alt_y)
				config["is_facing_right"] = (dir > 0)
			"updraft_zone":
				config["position"] = Vector2(270.0, alt_y)
				config["lift_force"] = 450.0
			"turbulence_zone":
				config["position"] = Vector2(270.0, alt_y)
				config["multiplier"] = 0.45
				
		spawn_obstacle(selected_type, config)

# Kiểm tra tương tác Troop <-> Obstacle mỗi frame.
# Va chạm do physics đảm nhiệm: Troop (Area2D) khai báo CollisionShape2D + mask layer 2,
# nên get_overlapping_areas() trả về đúng các obstacle đang chạm (không tính toán thủ công nữa).
func check_troop_interactions(troop: Troop, delta: float) -> void:
	if troop == null or not troop.is_active or troop.has_landed:
		if _overlapping_lethal_obs != null:
			troop.on_obstacle_exited(_overlapping_lethal_obs)
			_overlapping_lethal_obs = null
		return
		
	# Dọn dẹp các obstacle đã bị giải phóng (freed)
	var i = active_obstacles.size() - 1
	while i >= 0:
		if not is_instance_valid(active_obstacles[i]):
			active_obstacles.remove_at(i)
		i -= 1
		
	var has_any_lethal_overlap = false
	
	for area in troop.get_overlapping_areas():
		var obs := area as Obstacle
		if obs == null or not is_instance_valid(obs):
			continue
		if obs.is_warning_active or not obs.is_ready_to_act:
			continue
		
		# 1. VÙNG ĐẶC BIỆT (ZONE_MODIFIER) -> Áp dụng hiệu ứng liên tục lên Troop
		if obs.obstacle_category == Obstacle.ObstacleCategory.ZONE_MODIFIER:
			obs.apply_zone_effect(troop, delta)
			zone_effect_applied.emit(obs, str(obs.zone_effect))
			
		# 2. VẬT CẢN NGUY HIỂM (LETHAL hoặc STRUCTURAL)
		elif obs.obstacle_category in [Obstacle.ObstacleCategory.LETHAL, Obstacle.ObstacleCategory.STRUCTURAL]:
			has_any_lethal_overlap = true
			if _overlapping_lethal_obs != obs:
				_overlapping_lethal_obs = obs
				troop.on_obstacle_entered(obs)
				
	# Nếu không còn chạm vật cản lethal nào nữa -> Báo exited để reset Coyote Time
	if not has_any_lethal_overlap and _overlapping_lethal_obs != null:
		troop.on_obstacle_exited(_overlapping_lethal_obs)
		_overlapping_lethal_obs = null
