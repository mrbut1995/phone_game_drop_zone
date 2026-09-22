class_name WorldController
extends Node

signal troop_landed(landing_pos: Vector2)
signal troop_hit_obstacle(obstacle: Node2D)

# Tham chiếu được gán trực tiếp trong game.tscn
@export var world_node: Node2D
@export var camera: Camera2D
@export var spawner_controller: SpawnerController

var active_troop: Troop = null
var target_zone: TargetZone = null

const DROP_START_POS: Vector2 = Vector2(270.0, 90.0)
const GROUND_Y: float = 840.0

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

func apply_level_config(level_data: LevelData) -> void:
	_ensure_world_elements()
	
	if target_zone:
		target_zone.configure(
			level_data.target_moving,
			level_data.target_speed,
			level_data.target_move_range
		)
		
	# Toàn bộ obstacle được SpawnerController khởi tạo từ scene tương ứng,
	# không tạo node bằng code trong WorldController nữa.
	if spawner_controller:
		spawner_controller.spawn_level_obstacles(level_data)
	else:
		push_warning("WorldController: chưa gán spawner_controller nên không thể spawn obstacle")

func prepare_troop_for_drop() -> void:
	_ensure_world_elements()
	if active_troop:
		# Điểm xuất phát hơi ngẫu nhiên nhẹ quanh tâm (240 - 300)
		var start_x = randf_range(250.0, 290.0)
		active_troop.init_troop(Vector2(start_x, DROP_START_POS.y), GROUND_Y)
		
	if camera:
		camera.position = Vector2(270.0, 480.0)
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
			var target_cam_y = clamp(active_troop.position.y + 120.0, 480.0, GROUND_Y - 240.0)
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
