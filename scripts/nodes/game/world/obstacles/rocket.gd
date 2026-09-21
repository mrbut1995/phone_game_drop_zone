class_name RocketObstacle
extends Obstacle

var launch_speed: float = 260.0
var exhaust_particles: Array[Vector2] = []
var max_exhaust: int = 12

func _ready() -> void:
	has_warning = true
	warning_lead_time = 0.8
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 15.0
	auto_wrap_x = false
	auto_despawn_offscreen = true

func _draw() -> void:
	# 1. Trạng thái cảnh báo trước khi phóng (Warning indicator theo GDD 6)
	if is_warning_active:
		var blink = int(warning_timer * 10.0) % 2 == 0
		var warning_col = Color(1.0, 0.2, 0.2, 0.9) if blink else Color(1.0, 0.7, 0.0, 0.9)
		
		# Vẽ biểu tượng cảnh báo mũi tên nhấp nháy hướng lên
		var arrow_pts: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, -18.0),
			Vector2(-12.0, 0.0),
			Vector2(-4.0, 0.0),
			Vector2(-4.0, 16.0),
			Vector2(4.0, 16.0),
			Vector2(4.0, 0.0),
			Vector2(12.0, 0.0)
		])
		draw_colored_polygon(arrow_pts, warning_col)
		
		# Vòng tròn xung quanh
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, warning_col, 2.0)
		return
		
	# 2. Đang bay lên: Vẽ vệt lửa & khói phụt ra phía sau (Exhaust trail)
	for p in exhaust_particles:
		var local_p = p - position
		var alpha = clamp(1.0 - (local_p.length() / 70.0), 0.0, 0.8)
		draw_circle(local_p, randf_range(3.0, 6.0), Color(1.0, randf_range(0.4, 0.8), 0.1, alpha * 0.7))
		
	# 3. Thân tên lửa (Rocket fuselage)
	var body_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -22.0),   # Đầu nhọn hướng lên
		Vector2(-7.0, -8.0),
		Vector2(-7.0, 14.0),
		Vector2(7.0, 14.0),
		Vector2(7.0, -8.0)
	])
	draw_colored_polygon(body_pts, Color(0.9, 0.92, 0.95))
	
	# Đầu đạn màu đỏ
	var tip_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -22.0),
		Vector2(-7.0, -8.0),
		Vector2(7.0, -8.0)
	])
	draw_colored_polygon(tip_pts, Color(0.95, 0.2, 0.2))
	
	# Cánh đuôi tên lửa (Fins)
	draw_line(Vector2(-7.0, 8.0), Vector2(-14.0, 18.0), Color(0.95, 0.2, 0.2), 3.0)
	draw_line(Vector2(7.0, 8.0), Vector2(14.0, 18.0), Color(0.95, 0.2, 0.2), 3.0)
	
	# Lửa phụt dưới ống xả
	var flame_len = randf_range(12.0, 22.0)
	var flame_pts: PackedVector2Array = PackedVector2Array([
		Vector2(-5.0, 14.0),
		Vector2(0.0, 14.0 + flame_len),
		Vector2(5.0, 14.0)
	])
	draw_colored_polygon(flame_pts, Color(1.0, 0.6, 0.1))

func acting(delta: float) -> void:
	anim_time += delta
	# Bắn thẳng lên trên với tốc độ cao
	position.y -= launch_speed * delta
	
	# Tạo hạt khói/lửa xả
	exhaust_particles.push_front(position + Vector2(0.0, 18.0))
	if exhaust_particles.size() > max_exhaust:
		exhaust_particles.pop_back()
		
	# Vượt khỏi đỉnh màn hình thì dọn dẹp
	if position.y < bounds_top:
		queue_free()
