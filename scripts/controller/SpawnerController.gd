class_name SpawnerController
extends Node

signal troop_hit_obstacle(obstacle: Obstacle)
signal obstacle_spawned(obstacle: Obstacle)
signal zone_effect_applied(zone: Obstacle, effect_name: String)
signal item_collected(item_type: Item.ItemType, troop: Troop, world_pos: Vector2)

# Gán trực tiếp trong game.tscn
@export var world_node: Node2D

var active_obstacles: Array[Obstacle] = []
var active_items: Array[Item] = []

# Preload các PackedScene vật phẩm (Items) theo Update_Feature.md Section 1
const ITEM_COIN_SCENE: PackedScene = preload("res://nodes/game/world/items/coin.tscn")
const ITEM_SHIELD_SCENE: PackedScene = preload("res://nodes/game/world/items/shield_bubble.tscn")
const ITEM_BACKUP_SCENE: PackedScene = preload("res://nodes/game/world/items/backup_chute.tscn")

# Quản lý trạng thái overlap giữa Troop và từng obstacle
var _overlapping_lethal_obs: Obstacle = null

func clear_all_obstacles() -> void:
	for obs in active_obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	active_obstacles.clear()
	_overlapping_lethal_obs = null

func clear_all_items() -> void:
	for it in active_items:
		if is_instance_valid(it):
			it.queue_free()
	active_items.clear()

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
		host = world_node if (world_node != null and world_node.is_inside_tree()) else self
	host.add_child(obs)

	obs.setup(params)
	active_obstacles.append(obs)
	obstacle_spawned.emit(obs)
	return obs

# Tạo một Item trên thế giới
func spawn_item(scene: PackedScene, pos: Vector2, parent: Node2D = null) -> Item:
	if scene == null:
		return null
	var it: Item = scene.instantiate() as Item
	if it == null:
		return null

	# Đặt vị trí + pha nhấp nhô TRƯỚC khi add_child: Item._ready() lấy position làm mốc bob
	it.position = pos
	it.bob_phase = randf() * TAU

	var host: Node = parent
	if host == null or not host.is_inside_tree():
		host = world_node if (world_node != null and world_node.is_inside_tree()) else self
	host.add_child(it)
	it.base_y = pos.y
	active_items.append(it)
	return it

# Nối với signal "level_loaded" của LevelController trong game.tscn
func _on_level_loaded(level: BaseLevel) -> void:
	spawn_level_obstacles(level)
	spawn_level_items(level)

# Sinh obstacle theo các marker khai báo sẵn trong Level scene
func spawn_level_obstacles(level: BaseLevel) -> void:
	clear_all_obstacles()
	if level == null:
		return

	var container: Node2D = level.get_spawn_obstacles_container()
	for marker in level.get_spawn_markers():
		if marker.obstacle_scene == null:
			push_warning("SpawnerController: marker %s chưa gán obstacle_scene" % marker.name)
			continue
		spawn_obstacle(marker.obstacle_scene, marker.build_params(), container)

# Sinh vật phẩm (Coins, Shield Bubble, Backup Chute) theo tần suất khai báo trong Level scene
# (Update_Feature.md 1.4: Coin thường xuyên, Shield trung bình, Backup hiếm)
func spawn_level_items(level: BaseLevel) -> void:
	clear_all_items()
	if level == null:
		return

	var host = world_node if (world_node != null and world_node.is_inside_tree()) else self

	# 1. Các cụm coin uốn theo vòng cung (Update_Feature.md 6.5: xếp hình để khuyến khích lái theo quỹ đạo)
	var cluster_count: int = maxi(0, level.coin_cluster_count)
	var per_cluster: int = maxi(0, level.coins_per_cluster)
	for cluster in cluster_count:
		var start_x: float = randf_range(140.0, 400.0)
		var base_line_y: float = 230.0 + float(cluster) * 240.0
		var dir_sign: float = 1.0 if cluster % 2 == 0 else -1.0
		for c in per_cluster:
			var t: float = float(c) / float(maxi(1, per_cluster - 1))
			var cp := Vector2(
				clampf(start_x + dir_sign * (t - 0.5) * 140.0, 40.0, 500.0),
				base_line_y + sin(t * PI) * 26.0
			)
			spawn_item(ITEM_COIN_SCENE, cp, host)

	# 2. Shield Bubble: đặt lệch khỏi đường rơi tự nhiên để người chơi phải đánh đổi quỹ đạo (6.5)
	for i in maxi(0, level.shield_item_count):
		var shield_x: float = 110.0 if i % 2 == 0 else 430.0
		spawn_item(ITEM_SHIELD_SCENE, Vector2(shield_x, 360.0 + float(i) * 180.0), host)

	# 3. Backup Chute: hiếm, đặt ở tầng cao gần mặt đất
	for i in maxi(0, level.backup_item_count):
		spawn_item(ITEM_BACKUP_SCENE, Vector2(randf_range(160.0, 380.0), 600.0 + float(i) * 80.0), host)

# Kiểm tra tương tác Troop <-> Obstacles & Items mỗi frame
func check_troop_interactions(troop: Troop, delta: float) -> void:
	if troop == null or not troop.is_active or troop.has_landed:
		if _overlapping_lethal_obs != null:
			troop.on_obstacle_exited(_overlapping_lethal_obs)
			_overlapping_lethal_obs = null
		return
		
	# 1. Kiểm tra thu thập Vật phẩm (Items)
	var j = active_items.size() - 1
	while j >= 0:
		var it = active_items[j]
		if not is_instance_valid(it):
			active_items.remove_at(j)
		elif not it.is_collected and it.check_collection(troop.position):
			var it_pos = it.position
			var it_type = it.item_type
			it.collect(troop)
			item_collected.emit(it_type, troop, it_pos)
		j -= 1

	# 2. Kiểm tra tương tác Obstacles
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
		
		# VÙNG ĐẶC BIỆT (ZONE_MODIFIER) -> Áp dụng hiệu ứng liên tục lên Troop
		if obs.obstacle_category == Obstacle.ObstacleCategory.ZONE_MODIFIER:
			obs.apply_zone_effect(troop, delta)
			zone_effect_applied.emit(obs, str(obs.zone_effect))
			
		# VẬT CẢN NGUY HIỂM (LETHAL hoặc STRUCTURAL)
		elif obs.obstacle_category in [Obstacle.ObstacleCategory.LETHAL, Obstacle.ObstacleCategory.STRUCTURAL]:
			has_any_lethal_overlap = true
			if _overlapping_lethal_obs != obs:
				_overlapping_lethal_obs = obs
				troop.on_obstacle_entered(obs)
				
	# Không còn chạm vật cản lethal nào nữa -> báo exited để reset trạng thái theo dõi
	if not has_any_lethal_overlap and _overlapping_lethal_obs != null:
		troop.on_obstacle_exited(_overlapping_lethal_obs)
		_overlapping_lethal_obs = null
