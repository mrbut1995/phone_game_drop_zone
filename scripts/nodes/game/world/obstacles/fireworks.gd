class_name FireworksObstacle
extends Obstacle

enum Stage { WARNING, RISING, BURSTING, FINISHED }
var current_stage: Stage = Stage.WARNING

var rise_speed: float = 320.0
var target_burst_y: float = 400.0
var burst_time: float = 0.0
var burst_duration: float = 1.2
var max_burst_radius: float = 36.0
var spark_count: int = 12
var burst_color: Color = Color(1.0, 0.3, 0.6)

func _ready() -> void:
	has_warning = true
	warning_lead_time = 0.7
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 12.0
	auto_wrap_x = false
	current_stage = Stage.WARNING

func on_setup(params: Dictionary) -> void:
	if params.has("burst_y"):
		target_burst_y = params["burst_y"]
	if params.has("color"):
		burst_color = params["color"]

func _draw() -> void:
	# 1. Cảnh báo mặt đất
	if current_stage == Stage.WARNING:
		var blink = int(warning_timer * 12.0) % 2 == 0
		var col = Color(1.0, 0.8, 0.1, 0.9) if blink else Color(1.0, 0.2, 0.2, 0.9)
		draw_circle(Vector2.ZERO, 14.0, Color(col.r, col.g, col.b, 0.3))
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 16, col, 2.5)
		draw_line(Vector2(0, 10), Vector2(0, -10), col, 3.0)
		return
		
	# 2. Đang bay vút lên
	if current_stage == Stage.RISING:
		# Tia lửa rocket dẫn đường
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
		draw_line(Vector2.ZERO, Vector2(0, 20.0), Color(1.0, 0.7, 0.2), 3.0)
		return
		
	# 3. Nổ bung pháo hoa lấp lánh (Sparkling burst)
	if current_stage == Stage.BURSTING:
		var p = burst_time / burst_duration
		var cur_radius = lerp(8.0, max_burst_radius, ease(p, 0.3))
		var alpha = clamp(1.0 - p, 0.0, 1.0)
		
		# Vòng sóng xung kích mỏng
		draw_arc(Vector2.ZERO, cur_radius, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, alpha * 0.4), 1.5)
		
		# Các tia hoa lửa tỏa đều các hướng
		for i in range(spark_count):
			var ang = (float(i) / float(spark_count)) * TAU
			var dir_vec = Vector2(cos(ang), sin(ang))
			var spark_end = dir_vec * cur_radius
			var spark_start = dir_vec * (cur_radius * 0.4)
			var col = burst_color
			col.a = alpha
			draw_line(spark_start, spark_end, col, max(1.5, 3.5 * alpha))
			draw_circle(spark_end, 2.0, Color(1.0, 1.0, 1.0, alpha))

func acting(delta: float) -> void:
	match current_stage:
		Stage.WARNING:
			# Đã được Obstacle base class xử lý timer
			if is_ready_to_act:
				current_stage = Stage.RISING
				
		Stage.RISING:
			position.y -= rise_speed * delta
			if position.y <= target_burst_y:
				position.y = target_burst_y
				current_stage = Stage.BURSTING
				burst_time = 0.0
				
		Stage.BURSTING:
			burst_time += delta
			var p = burst_time / burst_duration
			hitbox_radius = lerp(12.0, max_burst_radius * 0.8, p)
			if burst_time >= burst_duration:
				current_stage = Stage.FINISHED
				queue_free()
