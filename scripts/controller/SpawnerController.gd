class_name SpawnerController
extends Node

signal troop_hit_obstacle(obstacle: Obstacle)
signal obstacle_spawned(obstacle: Obstacle)
signal zone_effect_applied(zone: Obstacle, effect_name: String)

# Gán trực tiếp trong game.tscn
@export var world_node: Node2D

var active_obstacles: Array[Obstacle] = []

# Danh mục obstacle KHÔNG còn hard-code trong code.
# Mỗi Level scene tự khai báo các marker ObstacleSpawn (con của node SpawnObstacles),
# mỗi marker gắn đúng PackedScene + tham số riêng -> xem level_1.tscn ... level_6.tscn.

# Quản lý trạng thái overlap giữa Troop và từng obstacle
var _overlapping_lethal_obs: Obstacle = null

func clear_all_obstacles() -> void:
	for obs in active_obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	active_obstacles.clear()
	_overlapping_lethal_obs = null

# Tạo một Obstacle từ PackedScene (scene nào là do Level scene quyết định) và truyền cấu hình
func spawn_obstacle(scene: PackedScene, params: Dictionary = {}, parent: Node2D = null) -> Obstacle:
	if scene == null:
		push_warning("SpawnerController: chưa gán obstacle_scene cho marker")
		return null

	var obs: Obstacle = scene.instantiate() as Obstacle
	if obs == null:
		push_warning("SpawnerController: scene không phải Obstacle: " + scene.resource_path)
		return null

	var host: Node = parent
	if host == null or not host.is_inside_tree():
		# An toàn: nếu container của level chưa nằm trong tree (thứ tự connection bị đổi)
		# thì add vào world_node để _ready() của obstacle chạy đúng (các @onready cần node con).
		host = world_node if (world_node != null and world_node.is_inside_tree()) else self
	host.add_child(obs)

	obs.setup(params)
	active_obstacles.append(obs)
	obstacle_spawned.emit(obs)
	return obs

# Nối với signal "level_loaded" của LevelController trong game.tscn
func _on_level_loaded(level: BaseLevel) -> void:
	spawn_level_obstacles(level)

# Sinh obstacle theo các marker khai báo sẵn trong Level scene
func spawn_level_obstacles(level: BaseLevel) -> void:
	clear_all_obstacles()
	if level == null:
		return

	# Obstacle được add vào container "SpawnObstacles" của level (KHÔNG phải vào marker)
	# để toạ độ của chúng khớp hệ toạ độ của level.
	var container: Node2D = level.get_spawn_obstacles_container()
	for marker in level.get_spawn_markers():
		if marker.obstacle_scene == null:
			push_warning("SpawnerController: marker %s chưa gán obstacle_scene" % marker.name)
			continue
		spawn_obstacle(marker.obstacle_scene, marker.build_params(), container)

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
				# Troop phát signal va chạm NGAY khi overlap (không chờ đệm)
				troop.on_obstacle_entered(obs)
				
	# Không còn chạm vật cản lethal nào nữa -> báo exited để reset trạng thái theo dõi
	if not has_any_lethal_overlap and _overlapping_lethal_obs != null:
		troop.on_obstacle_exited(_overlapping_lethal_obs)
		_overlapping_lethal_obs = null
