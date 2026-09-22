class_name WorldController
extends Node

signal troop_landed(landing_pos: Vector2)
signal troop_hit_obstacle(obstacle: Node2D)

# Tham chiếu được gán trực tiếp trong game.tscn
@export var world_node: Node2D
@export var camera: Camera2D
@export var spawner_controller: SpawnerController

# Scene hiệu ứng nổ khi va chạm - đổi được trong Inspector nếu muốn art khác
@export var hit_effect_scene: PackedScene = preload("res://nodes/game/world/fx/hit_effect.tscn")

var active_troop: Troop = null
var target_zone: TargetZone = null
var current_level: BaseLevel = null

const DROP_START_POS: Vector2 = Vector2(270.0, 90.0)
const DEFAULT_GROUND_Y: float = 840.0
# Cao độ mặt đất thực tế của màn đang chơi (lấy từ BaseLevel.ground_y)
var ground_y: float = DEFAULT_GROUND_Y

func _ready() -> void:
	_ensure_world_elements()

func _ensure_world_elements() -> void:
	if world_node == null:
		return

	# Troop + TargetZone được khai báo sẵn trong scene (không tạo node bằng code)
	target_zone = world_node.get_node_or_null("TargetZone") as TargetZone
	active_troop = world_node.get_node_or_null("Troop") as Troop
	if target_zone == null:
		push_warning("WorldController: thiếu node World/TargetZone trong scene")
	if active_troop == null:
		push_warning("WorldController: thiếu node World/Troop trong scene")
		return

	if not active_troop.landed.is_connected(_on_troop_landed):
		active_troop.landed.connect(_on_troop_landed)
	if not active_troop.hit_obstacle.is_connected(_on_troop_hit_obstacle):
		active_troop.hit_obstacle.connect(_on_troop_hit_obstacle)

# Nối với signal "level_loaded" của LevelController trong game.tscn
func _on_level_loaded(level: BaseLevel) -> void:
	apply_level(level)

# Thay màn cũ bằng Level scene vừa được instantiate, và áp cấu hình của màn lên bia mục tiêu
func apply_level(level: BaseLevel) -> void:
	if level == null or world_node == null:
		return

	# Gỡ màn cũ (nếu có) và đưa màn mới vào dưới cùng của World
	if is_instance_valid(current_level):
		world_node.remove_child(current_level)
		current_level.queue_free()
	current_level = level
	world_node.add_child(level)
	world_node.move_child(level, 0)

	ground_y = level.ground_y

	# Cấu hình bia mục tiêu theo dữ liệu khai báo trong Level scene.
	# Obstacle đã được SpawnerController sinh ra theo marker (xem _on_level_loaded bên đó).
	_ensure_world_elements()
	if target_zone:
		level.configure_target_zone(target_zone)

func prepare_troop_for_drop() -> void:
	_ensure_world_elements()
	if active_troop:
		# Điểm xuất phát hơi ngẫu nhiên nhẹ quanh tâm (240 - 300)
		var start_x = randf_range(250.0, 290.0)
		active_troop.init_troop(Vector2(start_x, DROP_START_POS.y), ground_y)
		
	if camera:
		camera.position = Vector2(270.0, 480.0)
		camera.offset = Vector2.ZERO
		camera.zoom = Vector2.ONE

func release_troop() -> void:
	if active_troop:
		active_troop.start_drop()

func update_troop_forces(tilt_force: float, wind_force: float, delta: float = 0.0) -> void:
	if active_troop and active_troop.is_active:
		active_troop.apply_forces(tilt_force, wind_force)
		
		# Kiểm tra tương tác vật lý với các chướng ngại vật và vùng đặc biệt
		if spawner_controller:
			spawner_controller.check_troop_interactions(active_troop, delta)
		
		# Camera bám theo độ cao của nhân vật
		if camera:
			var target_cam_y = clamp(active_troop.position.y + 120.0, 480.0, ground_y - 240.0)
			camera.position.y = lerp(camera.position.y, target_cam_y, 0.08)

func _on_troop_landed(pos: Vector2) -> void:
	troop_landed.emit(pos)
	
	# Zoom nhẹ camera vào khoảnh khắc chạm đất (GDD 7.4)
	if camera:
		var tw = create_tween()
		tw.tween_property(camera, "zoom", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.6)
		tw.tween_property(camera, "zoom", Vector2.ONE, 0.3)

func _on_troop_hit_obstacle(obs: Node2D) -> void:
	troop_hit_obstacle.emit(obs)

# Phản hồi khi lính đụng chướng ngại vật: hiệu ứng nổ + rung camera
func play_hit_feedback(hit_pos: Vector2) -> void:
	if world_node == null:
		return

	# Hiệu ứng nổ tại điểm va chạm (scene khai báo sẵn, tự huỷ khi hết animation)
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
	var text_str: String = "+%d %s" % [score_info["points"], score_info["ring_name"]]
	if score_info.has("multiplier") and score_info["multiplier"] > 1:
		text_str += "\nCOMBO x%d!" % score_info["multiplier"]
		
	label.text = text_str
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = land_pos + Vector2(-120, -50)
	label.size = Vector2(240, 50)
	label.add_theme_color_override("font_color", score_info["color"])
	label.add_theme_font_size_override("font_size", 20 if score_info["points"] >= 70 else 16)
	label.z_index = 25
	world_node.add_child(label)
	
	# Tween bay lên và mờ dần
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.chain().tween_callback(label.queue_free)
