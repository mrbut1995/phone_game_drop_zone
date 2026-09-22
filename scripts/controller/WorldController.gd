class_name WorldController
extends Node

signal troop_landed(landing_pos: Vector2)
signal troop_hit_obstacle(obstacle: Node2D)
signal individual_troop_landed(troop: Troop, landing_pos: Vector2)
signal individual_troop_hit_obstacle(troop: Troop, obstacle: Node2D)
signal individual_troop_shield_broken(troop: Troop)

# Tham chiếu được gán trực tiếp trong game.tscn
@export var world_node: Node2D
@export var camera: Camera2D
@export var spawner_controller: SpawnerController

# Scene hiệu ứng nổ khi va chạm - đổi được trong Inspector nếu muốn art khác
@export var hit_effect_scene: PackedScene = preload("res://nodes/game/world/fx/hit_effect.tscn")
const TROOP_SCENE: PackedScene = preload("res://nodes/game/world/player/troop.tscn")

var active_troop: Troop = null # Troop dẫn đầu (gần đất nhất)
var active_troops: Array[Troop] = [] # Danh sách toàn bộ troop đang hoạt động (Update_Feature.md Section 2)
var target_zone: TargetZone = null
var current_level: BaseLevel = null

const DROP_START_POS: Vector2 = Vector2(270.0, 90.0)
const DEFAULT_GROUND_Y: float = 840.0
var ground_y: float = DEFAULT_GROUND_Y

func _ready() -> void:
	_ensure_world_elements()

func _ensure_world_elements() -> void:
	if world_node == null:
		return

	# Bia mục tiêu khai báo sẵn trong scene (Troop được sinh runtime theo Continuous Drop)
	target_zone = world_node.get_node_or_null("TargetZone") as TargetZone
	if target_zone == null:
		push_warning("WorldController: thiếu node World/TargetZone trong scene")

# Gắn signal cho 1 Troop bất kỳ (dùng khi spawn runtime hoặc bind troop có sẵn)
func _bind_troop_signals(troop: Troop) -> void:
	if not troop.landed.is_connected(_on_troop_landed_handler):
		troop.landed.connect(func(pos): _on_troop_landed_handler(troop, pos))
	if not troop.hit_obstacle.is_connected(_on_troop_hit_obstacle_handler):
		troop.hit_obstacle.connect(func(obs): _on_troop_hit_obstacle_handler(troop, obs))
	if not troop.shield_broken.is_connected(_on_troop_shield_broken_handler):
		troop.shield_broken.connect(func(): _on_troop_shield_broken_handler(troop))

# Nối với signal "level_loaded" của LevelController trong game.tscn
func _on_level_loaded(level: BaseLevel) -> void:
	apply_level(level)

# Thay màn cũ bằng Level scene vừa được instantiate, và áp cấu hình của màn lên bia mục tiêu
func apply_level(level: BaseLevel) -> void:
	if level == null or world_node == null:
		return

	if is_instance_valid(current_level):
		world_node.remove_child(current_level)
		current_level.queue_free()
	current_level = level
	world_node.add_child(level)
	world_node.move_child(level, 0)

	ground_y = level.ground_y

	_ensure_world_elements()
	if target_zone:
		level.configure_target_zone(target_zone)

# Dọn dẹp toàn bộ troops cũ khi reset hoặc đổi màn
func clear_all_troops() -> void:
	for t in active_troops:
		if is_instance_valid(t):
			t.queue_free()
	active_troops.clear()
	active_troop = null

# Số nhân vật còn đang trên không (chưa chạm đất) - dùng để giới hạn spawn đồng thời
func get_airborne_count() -> int:
	var n: int = 0
	for t in active_troops:
		if is_instance_valid(t) and not t.has_landed:
			n += 1
	return n

# Tạo một Troop mới trong chế độ Continuous Drop (Update_Feature.md Section 2)
func spawn_continuous_troop(spawn_x: float, color_idx: int) -> Troop:
	_ensure_world_elements()
	var troop: Troop = TROOP_SCENE.instantiate() as Troop
	if troop == null:
		return null
		
	world_node.add_child(troop)
	_bind_troop_signals(troop)
	
	var drop_pos = Vector2(spawn_x, DROP_START_POS.y)
	troop.init_troop(drop_pos, ground_y, color_idx)
	troop.start_drop()
	active_troops.append(troop)
	# Nhân vật vừa thả đảm nhận vai trò dẫn đầu nếu chưa có ai
	if active_troop == null or not is_instance_valid(active_troop):
		active_troop = troop
	return troop

# Cao độ nhân vật dẫn đầu (dùng để tính gió theo độ cao; chưa có thì lấy điểm thả)
func get_lead_y() -> float:
	if active_troop != null and is_instance_valid(active_troop):
		return active_troop.position.y
	return DROP_START_POS.y

# Chuẩn bị cho lượt đầu tiên
func prepare_troop_for_drop() -> void:
	clear_all_troops()
	if camera:
		camera.position = Vector2(270.0, 480.0)
		camera.offset = Vector2.ZERO
		camera.zoom = Vector2.ONE

# Áp dụng Unified Tilt lên TOÀN BỘ các nhân vật đang rơi đồng thời (Update_Feature.md Section 3)
func update_troop_forces(tilt_force: float, wind_force: float, delta: float = 0.0) -> void:
	# 1. Dọn dẹp troop không còn hợp lệ
	var i = active_troops.size() - 1
	while i >= 0:
		if not is_instance_valid(active_troops[i]):
			active_troops.remove_at(i)
		i -= 1
		
	if active_troops.is_empty():
		return

	# 2. Tìm nhân vật gần chạm đất nhất (Lead Troop) để highlight (Update_Feature.md 3.2)
	var max_y: float = -9999.0
	var lead: Troop = null
	for t in active_troops:
		if is_instance_valid(t) and t.is_active and not t.has_landed:
			if t.position.y > max_y:
				max_y = t.position.y
				lead = t

	active_troop = lead
	for t in active_troops:
		if is_instance_valid(t):
			t.is_lead_troop = (t == lead)

	# 3. Tác động lực ngang tổng và kiểm tra va chạm / nhặt item cho từng nhân vật
	for t in active_troops:
		if is_instance_valid(t) and (t.is_active or t.is_knocked_out):
			if t.is_active:
				t.apply_forces(tilt_force, wind_force)
			if spawner_controller:
				spawner_controller.check_troop_interactions(t, delta)

	# 4. Camera bám mượt theo nhân vật dẫn đầu
	if camera and lead != null:
		var target_cam_y = clamp(lead.position.y + 120.0, 480.0, ground_y - 240.0)
		camera.position.y = lerp(camera.position.y, target_cam_y, 0.08)

func _on_troop_landed_handler(troop: Troop, pos: Vector2) -> void:
	individual_troop_landed.emit(troop, pos)
	troop_landed.emit(pos)
	
	# Zoom nhẹ camera vào khoảnh khắc chạm đất (GDD 7.4)
	if camera:
		var tw = create_tween()
		tw.tween_property(camera, "zoom", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.6)
		tw.tween_property(camera, "zoom", Vector2.ONE, 0.3)

func _on_troop_hit_obstacle_handler(troop: Troop, obs: Node2D) -> void:
	individual_troop_hit_obstacle.emit(troop, obs)
	troop_hit_obstacle.emit(obs)

func _on_troop_shield_broken_handler(troop: Troop) -> void:
	individual_troop_shield_broken.emit(troop)

# Phản hồi khi lính đụng chướng ngại vật: hiệu ứng nổ + rung camera
func play_hit_feedback(hit_pos: Vector2) -> void:
	if world_node == null:
		return

	if hit_effect_scene != null:
		var fx := hit_effect_scene.instantiate() as HitEffect
		if fx != null:
			world_node.add_child(fx)
			fx.play_at(hit_pos)

	_shake_camera()

# Rung camera ngắn khi va chạm (giảm dần biên độ)
func _shake_camera(duration: float = 0.32, magnitude: float = 14.0) -> void:
	if camera == null:
		return
	var steps: int = max(2, int(duration / 0.04))
	var tw := create_tween()
	for i in steps:
		var falloff: float = 1.0 - float(i) / float(steps)
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * magnitude * falloff
		tw.tween_property(camera, "offset", offset, 0.04)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.05)

# Hiệu ứng nổi chữ điểm số (Floating text) tại vị trí đáp
func spawn_floating_score(score_info: Dictionary, land_pos: Vector2) -> void:
	var label = Label.new()
	var text_str: String = score_info.get("text", "")
	if text_str == "":
		text_str = "+%d %s" % [score_info.get("points", 0), score_info.get("ring_name", "")]
		if score_info.has("multiplier") and score_info["multiplier"] > 1:
			text_str += "\nCOMBO x%d!" % score_info["multiplier"]
		
	label.text = text_str
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = land_pos + Vector2(-120, -50)
	label.size = Vector2(240, 50)
	label.add_theme_color_override("font_color", score_info.get("color", Color.WHITE))
	label.add_theme_font_size_override("font_size", 20 if score_info.get("points", 0) >= 70 else 16)
	label.z_index = 25
	world_node.add_child(label)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.chain().tween_callback(label.queue_free)
